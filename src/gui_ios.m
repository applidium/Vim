/* vi:set ts=8 sts=4 sw=4 ft=objc:
 *
 * VIM - Vi IMproved		by Bram Moolenaar
 *				MacVim GUI port by Bjorn Winckler
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */
/*
 * gui_ios.m
 *
 * Hooks for the Vim gui code.  Mainly passes control on to MMBackend.
 */

#import "vim.h"
#import <UIKit/UIKit.h>

#define DEBUG_IOS_DRAWING 0
void CGLayerCopyRectToRect(CGLayerRef layer, CGRect sourceRect, CGRect targetRect);
@class VImViewController;
@class VImTextView;
struct {
    UIWindow * window;
    VImViewController * view_controller;
    CGLayerRef layer;
    CGColorRef fg_color;
    CGColorRef bg_color;
    int         blink_state;
    long        blink_wait;
    long        blink_on;
    long        blink_off;
    NSTimer *   blink_timer;
} gui_ios;

enum blink_state {
    BLINK_NONE,     /* not blinking at all */
    BLINK_OFF,      /* blinking, cursor is not shown */
    BLINK_ON        /* blinking, cursor is shown */
};

#pragma mark -
#pragma mark VImTextView

@interface VImTextView : UIView {
    UIView *   _inputAcccessoryView;
}
@property (nonatomic, retain) UIView * inputAccessoryView;
@end

@implementation VImTextView
@synthesize inputAccessoryView = _inputAcccessoryView;
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIButton * escButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [escButton addTarget:self action:@selector(sendSpecialKey:) forControlEvents:UIControlEventTouchUpInside];
        _inputAcccessoryView = [escButton retain];
    }
    return self;
}

- (void)dealloc {
    [_inputAcccessoryView release];
    if (gui_ios.layer) {
        CGLayerRelease(gui_ios.layer);
        gui_ios.layer = NULL;
    }
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    if (gui_ios.layer != NULL) {
#if DEBUG_IOS_DRAWING
        CGContextDrawLayerAtPoint(UIGraphicsGetCurrentContext(), CGPointMake(50.0f, 50.0f), gui_ios.layer);
#else
        CGContextDrawLayerAtPoint(UIGraphicsGetCurrentContext(), CGPointZero, gui_ios.layer);
#endif
    } else {
#if DEBUG_IOS_DRAWING
        gui_ios.layer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), CGSizeMake(600.0f, 600.0f), nil);
#else
        gui_ios.layer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), CGSizeMake(1024.0f, 1024.0f), nil);
#endif
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    gui_resize_shell(self.bounds.size.width, self.bounds.size.height);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    gui_resize_shell(self.bounds.size.width, self.bounds.size.height);
}
@end



#pragma mark -
#pragma VImViewController

@interface VImViewController : UIViewController <UIKeyInput, UITextInputTraits> {
    VImTextView * _textView;
}
- (void)flush;
- (void)blinkCursorTimer:(NSTimer *)timer;
@end

@implementation VImViewController
- (void)loadView {
    self.view = [[[UIView alloc] init] autorelease];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.view.backgroundColor = [UIColor purpleColor];

    _textView = [[VImTextView alloc] initWithFrame:CGRectZero];
    _textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:_textView];
    _textView.frame = self.view.bounds;
    [_textView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)keyboardWasShown:(NSNotification *)notification {
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRectInView = [self.view.window convertRect:keyboardRect toView:_textView];
    _textView.frame = CGRectMake(0.0f, 0.0f, _textView.frame.size.width, keyboardRectInView.origin.y);
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRectInView = [self.view.window convertRect:keyboardRect toView:_textView];
    _textView.frame = CGRectMake(0.0f, 0.0f, _textView.frame.size.width, keyboardRectInView.origin.y);
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)flush {
    [_textView setNeedsDisplay];
}

- (void)sendSpecialKey:(UIButton *)sender {
    NSLog(@"Sending special key !");
    char escapeString[] = {ESC, 0};
    [self insertText:[NSString stringWithUTF8String:escapeString]];
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return NO;
}

- (BOOL)hasText {
    return YES;
}

- (void)insertText:(NSString *)text {
    add_to_input_buf((char_u *)[text UTF8String], [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    [_textView setNeedsDisplay];
}

- (void)deleteBackward {
    char escapeString[] = {BS, 0};
    [self insertText:[NSString stringWithUTF8String:escapeString]];
}

- (UITextAutocapitalizationType)autocapitalizationType {
    return UITextAutocapitalizationTypeNone;
}

- (UIKeyboardType)keyboardType {
    return UIKeyboardTypeDefault;
}

- (void)blinkCursorTimer:(NSTimer *)timer {
    NSTimeInterval on_time, off_time;
    
    
    [gui_ios.blink_timer invalidate];
    if (gui_ios.blink_state == BLINK_ON) {
        gui_undraw_cursor();
        gui_ios.blink_state = BLINK_OFF;
        
        off_time = gui_ios.blink_off / 1000.0;
        gui_ios.blink_timer = [NSTimer scheduledTimerWithTimeInterval:off_time
                                                               target:self
                                                             selector:@selector(blinkCursorTimer:)
                                                             userInfo:nil
                                                              repeats:NO];
    }
    else if (gui_ios.blink_state == BLINK_OFF) {
        gui_update_cursor(TRUE, FALSE);
        gui_ios.blink_state = BLINK_ON;
        
        on_time = gui_ios.blink_on / 1000.0;
        gui_ios.blink_timer = [NSTimer scheduledTimerWithTimeInterval:on_time
                                                               target:self
                                                             selector:@selector(blinkCursorTimer:)
                                                             userInfo:nil
                                                              repeats:NO];
    }
    [_textView setNeedsDisplay];
}

@end



#pragma mark -
#pragma mark VImAppDelegate

@interface VImAppDelegate : NSObject <UIApplicationDelegate> {
}
@end

@implementation VImAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Per Apple's documentation : Performs the specified selector on the application’s main thread during that thread’s next run loop cycle. These methods give you the option of blocking the current thread until the selector is performed.
    [self performSelectorOnMainThread:@selector(_VImMain) withObject:nil waitUntilDone:NO];
    return YES;
}

- (void)_VImMain {
    vim_setenv((char_u *)"VIMRUNTIME", (char_u *)[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"runtime"] UTF8String]);

    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        vim_setenv((char_u *)"HOME", (char_u *)[[paths objectAtIndex:0] UTF8String]);
    }

    char * argv[] = { "vim" };
    VimMain(1, argv);
}
@end



#pragma mark -
#pragma mark Helper C functions

void CGLayerCopyRectToRect(CGLayerRef layer, CGRect sourceRect, CGRect targetRect) {
    CGContextRef context = CGLayerGetContext(layer);
    
    CGRect destinationRect = targetRect;
    destinationRect.size.width = MIN(targetRect.size.width, sourceRect.size.width);
    destinationRect.size.height = MIN(targetRect.size.height, sourceRect.size.height);
    
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextAddRect(context, destinationRect);
    CGContextClip(context);
    CGContextDrawLayerAtPoint(context, CGPointMake(destinationRect.origin.x - sourceRect.origin.x, destinationRect.origin.y - sourceRect.origin.y), layer);
    CGContextRestoreGState(context);
    
#if DEBUG_IOS_DRAWING
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1.0f);
    CGFloat line[2] = {2.0f, 1.0f};
    CGContextSetLineDash(context, 0.0f, line, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    CGContextStrokeRect(context, sourceRect);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextStrokeRect(context, targetRect);
    CGContextRestoreGState(context);
#endif
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"VImAppDelegate");
    [pool release];
    return retVal;
}



#pragma mark -
#pragma mark VIm C functions

/*
 * Parse the GUI related command-line arguments.  Any arguments used are
 * deleted from argv, and *argc is decremented accordingly.  This is called
 * when vim is started, whether or not the GUI has been started.
 * NOTE: This function will be called twice if the Vim process forks.
 */
    void
gui_mch_prepare(int *argc, char **argv)
{
    // NOTE! Vim expects this method to remove args that it handles from the
    // arg list but if the process then forks then these arguments will not
    // reach the child process due to the way forking is handled on Mac OS X.
    //
    // Thus, only delete arguments that imply that no forking is done.
    //
    // If you add an argument that does not imply no forking, then do not
    // delete it from the arg list.  Such arguments must be ignored in main.c
    // command_line_scan() or Vim will issue an error on startup when that
    // argument is used.
    printf("%s\n",__func__);  
}


/*
 * Check if the GUI can be started.  Called before gvimrc is sourced.
 * Return OK or FAIL.
 */
    int
gui_mch_init_check(void)
{
    printf("%s\n",__func__);  
    return OK;
}


/*
 * Initialise the GUI.  Create all the windows, set up all the call-backs etc.
 * Returns OK for success, FAIL when the GUI can't be started.
 */
    int
gui_mch_init(void)
{
    printf("%s\n",__func__);  
    set_option_value((char_u *)"termencoding", 0L, (char_u *)"utf-8", 0);

    gui_ios.window = [[UIWindow alloc] init];
    gui_ios.view_controller = [[VImViewController alloc] init];
    gui_ios.window.rootViewController = gui_ios.view_controller;
    gui_ios.window.backgroundColor = [UIColor purpleColor];
    [gui_ios.view_controller release];
    
    gui_mch_def_colors();
    
    set_normal_colors();

    gui_check_colors();
    gui.def_norm_pixel = gui.norm_pixel;
    gui.def_back_pixel = gui.back_pixel;

    return OK;
}



    void
gui_mch_exit(int rc)
{
    printf("%s\n",__func__);  
}


/*
 * Open the GUI window which was created by a call to gui_mch_init().
 */
    int
gui_mch_open(void)
{
    [gui_ios.window makeKeyAndVisible];
    
    printf("%s\n",__func__);  
    return OK;
}


// -- Updating --------------------------------------------------------------


/*
 * Catch up with any queued X events.  This may put keyboard input into the
 * input buffer, call resize call-backs, trigger timers etc.  If there is
 * nothing in the X event queue (& no timers pending), then we return
 * immediately.
 */
    void
gui_mch_update(void)
{
    // This function is called extremely often.  It is tempting to do nothing
    // here to avoid reduced frame-rates but then it would not be possible to
    // interrupt Vim by presssing Ctrl-C during lengthy operations (e.g. after
    // entering "10gs" it would not be possible to bring Vim out of the 10 s
    // sleep prematurely).  Furthermore, Vim sometimes goes into a loop waiting
    // for keyboard input (e.g. during a "more prompt") where not checking for
    // input could cause Vim to lock up indefinitely.
    //
    // As a compromise we check for new input only every now and then. Note
    // that Cmd-. sends SIGINT so it has higher success rate at interrupting
    // Vim than Ctrl-C.

    printf("%s\n",__func__);  
}


/* Flush any output to the screen */
    void
gui_mch_flush(void)
{
    // This function is called way too often to be useful as a hint for
    // flushing.  If we were to flush every time it was called the screen would
    // flicker.
    printf("%s\n",__func__);
    CGContextFlush(CGLayerGetContext(gui_ios.layer));
    [gui_ios.view_controller flush];
}


/*
 * GUI input routine called by gui_wait_for_chars().  Waits for a character
 * from the keyboard.
 *  wtime == -1	    Wait forever.
 *  wtime == 0	    This should never happen.
 *  wtime > 0	    Wait wtime milliseconds for a character.
 * Returns OK if a character was found to be available within the given time,
 * or FAIL otherwise.
 */
    int
gui_mch_wait_for_chars(int wtime)
{
    // NOTE! In all likelihood Vim will take a nap when waitForInput: is
    // called, so force a flush of the command queue here.
    printf("%s\n",__func__);  
    printf("Waiting for %d\n", wtime);
    [[NSRunLoop currentRunLoop] acceptInputForMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:((NSTimeInterval)wtime)/1000.0]];
    printf("Finished waiting\n");

    return OK;
}


// -- Drawing ---------------------------------------------------------------


/*
 * Clear the whole text window.
 */
void
gui_mch_clear_all(void)
{
    printf("%s\n",__func__);
    CGContextRef context = CGLayerGetContext(gui_ios.layer);
    
    CGContextSetFillColorWithColor(context, gui_ios.bg_color);
    CGSize size = CGLayerGetSize(gui_ios.layer);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
}


/*
 * Clear a rectangular region of the screen from text pos (row1, col1) to
 * (row2, col2) inclusive.
 */
    void
gui_mch_clear_block(int row1, int col1, int row2, int col2)
{
    printf("%s\n",__func__);
    CGContextRef context = CGLayerGetContext(gui_ios.layer);
    
    CGContextSetFillColorWithColor(context, gui_ios.bg_color);
#if DEBUG_IOS_DRAWING
    CGContextSetFillColorWithColor(context, [UIColor purpleColor].CGColor);
#endif
    CGContextFillRect(context, CGRectMake(FILL_X(col1),
                                          FILL_Y(row1),
                                          FILL_X(col2+1)-FILL_X(col1),
                                          FILL_Y(row2+1)-FILL_Y(row1)));
}


void gui_mch_draw_string(int row, int col, char_u *s, int len, int flags) {
    printf("Draw flags = %d\n", flags);
    printf("%s\n",__func__);
    printf("Drawing \"%.*s\"\n", len, s);
    CGContextRef context = CGLayerGetContext(gui_ios.layer);

    //FIXME: Move this block somewhere else
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);
    CGContextSetShouldSmoothFonts(context, NO);

    CGContextSetCharacterSpacing(context, 0.0f);
    CGContextSetTextDrawingMode(context, kCGTextFill); 

    if (!(flags & DRAW_TRANSP)) {
        CGContextSetFillColorWithColor(context, gui_ios.bg_color);
        CGContextFillRect(context, CGRectMake(FILL_X(col), FILL_Y(row), FILL_X(col+len)-FILL_X(col), FILL_Y(row+1)-FILL_Y(row)));
    }

    CGContextSetFillColorWithColor(context, gui_ios.fg_color);


    NSString * string = [[NSString alloc] initWithBytes:s length:len encoding:NSUTF8StringEncoding];
    NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:(id)gui.norm_font, (NSString *)kCTFontAttributeName,
                                 [NSNumber numberWithBool:YES], kCTForegroundColorFromContextAttributeName,
                                 nil];
    NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    [attributes release];
    [string release];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString);
    // Set text position and draw the line into the graphics context
    CGContextSetTextPosition(context, TEXT_X(col), TEXT_Y(row));
    CTLineDraw(line, context);

    if (flags & DRAW_CURSOR) {
        CGContextSaveGState(context);
        CGContextSetBlendMode(context, kCGBlendModeDifference);
        CGContextFillRect(context, CGRectMake(FILL_X(col), FILL_Y(row),
                                              FILL_X(col+len)-FILL_X(col),
                                              FILL_Y(row+1)-FILL_Y(row)));
        CGContextRestoreGState(context);
    }
    CFRelease(line);
}


/*
 * Delete the given number of lines from the given row, scrolling up any
 * text further down within the scroll region.
 */
    void
gui_mch_delete_lines(int row, int num_lines)
{
    printf("%s\n",__func__);
    CGRect sourceRect = CGRectMake(FILL_X(gui.scroll_region_left),
                                   FILL_Y(row + num_lines),
                                   FILL_X(gui.scroll_region_right) - FILL_X(gui.scroll_region_left),
                                   FILL_Y(gui.scroll_region_bot+1) - FILL_Y(row + num_lines));

    CGRect targetRect = CGRectMake(FILL_X(gui.scroll_region_left),
                                   FILL_Y(row),
                                   FILL_X(gui.scroll_region_right) - FILL_X(gui.scroll_region_left),
                                   FILL_Y(gui.scroll_region_bot+1) - FILL_Y(row + num_lines));

    CGLayerCopyRectToRect(gui_ios.layer, sourceRect, targetRect);

    gui_clear_block(gui.scroll_region_bot - num_lines + 1,
                    gui.scroll_region_left,
                    gui.scroll_region_bot, gui.scroll_region_right);
}


/*
 * Insert the given number of lines before the given row, scrolling down any
 * following text within the scroll region.
 */
    void
gui_mch_insert_lines(int row, int num_lines)
{
    printf("%s\n",__func__);
    CGRect sourceRect = CGRectMake(FILL_X(gui.scroll_region_left),
                                   FILL_Y(row),
                                   FILL_X(gui.scroll_region_right) - FILL_X(gui.scroll_region_left),
                                   FILL_Y(gui.scroll_region_bot+1) - FILL_Y(row + num_lines));

    CGRect targetRect = CGRectMake(FILL_X(gui.scroll_region_left),
                                   FILL_Y(row + num_lines),
                                   FILL_X(gui.scroll_region_right) - FILL_X(gui.scroll_region_left),
                                   FILL_Y(gui.scroll_region_bot+1) - FILL_Y(row + num_lines));
    
    CGLayerCopyRectToRect(gui_ios.layer, sourceRect, targetRect);

    gui_clear_block(row, gui.scroll_region_left,
                    row + num_lines - 1, gui.scroll_region_right);
}

/*
 * Set the current text foreground color.
 */
    void
gui_mch_set_fg_color(guicolor_T color)
{
    printf("%s\n",__func__);
    gui_ios.fg_color = color;
}


/*
 * Set the current text background color.
 */
    void
gui_mch_set_bg_color(guicolor_T color)
{
    printf("%s\n",__func__);  
    gui_ios.bg_color = color;
}


/*
 * Set the current text special color (used for underlines).
 */
    void
gui_mch_set_sp_color(guicolor_T color)
{
    printf("%s\n",__func__);  
}


/*
 * Set default colors.
 */
void gui_mch_def_colors() {
    gui.norm_pixel = gui_mch_get_color((char_u *)"white");
    gui.back_pixel = gui_mch_get_color((char_u *)"black");
    gui.def_back_pixel = gui.back_pixel;
    gui.def_norm_pixel = gui.norm_pixel;
}


/*
 * Called when the foreground or background color has been changed.
 */
    void
gui_mch_new_colors(void)
{
    printf("%s\n",__func__);  
//    gui.def_back_pixel = gui.back_pixel;
//    gui.def_norm_pixel = gui.norm_pixel;

}

/*
 * Invert a rectangle from row r, column c, for nr rows and nc columns.
 */
    void
gui_mch_invert_rectangle(int r, int c, int nr, int nc)
{
    printf("%s\n",__func__);  
}

// -- Menu ------------------------------------------------------------------


/*
 * A menu descriptor represents the "address" of a menu as an array of strings.
 * E.g. the menu "File->Close" has descriptor { "File", "Close" }.
 */
   void
gui_mch_add_menu(vimmenu_T *menu, int idx)
{
    printf("%s\n",__func__);  
}


/*
 * Add a menu item to a menu
 */
    void
gui_mch_add_menu_item(vimmenu_T *menu, int idx)
{
    printf("%s\n",__func__);  
}


/*
 * Destroy the machine specific menu widget.
 */
    void
gui_mch_destroy_menu(vimmenu_T *menu)
{
    printf("%s\n",__func__);  
}


/*
 * Make a menu either grey or not grey.
 */
    void
gui_mch_menu_grey(vimmenu_T *menu, int grey)
{
    /* Only update menu if the 'grey' state has changed to avoid having to pass
     * lots of unnecessary data to MacVim.  (Skipping this test makes MacVim
     * pause noticably on mode changes. */
    printf("%s\n",__func__);  
}


/*
 * Make menu item hidden or not hidden
 */
    void
gui_mch_menu_hidden(vimmenu_T *menu, int hidden)
{
    printf("%s\n",__func__);  
}


/*
 * This is called when user right clicks.
 */
    void
gui_mch_show_popupmenu(vimmenu_T *menu)
{
    printf("%s\n",__func__);  
}


/*
 * This is called when a :popup command is executed.
 */
    void
gui_make_popup(char_u *path_name, int mouse_pos)
{
    printf("%s\n",__func__);  
}


/*
 * This is called after setting all the menus to grey/hidden or not.
 */
    void
gui_mch_draw_menubar(void)
{
    // The (main) menu draws itself in Mac OS X.
    printf("%s\n",__func__);  
}


    void
gui_mch_enable_menu(int flag)
{
    // The (main) menu is always enabled in Mac OS X.
    printf("%s\n",__func__);  
}

    void
gui_mch_set_menu_pos(int x, int y, int w, int h)
{
    printf("%s\n",__func__);  
    
    /*
     * The menu is always at the top of the screen.
     */
}

    void
gui_mch_show_toolbar(int showit)
{
    printf("%s\n",__func__);  
}




// -- Fonts -----------------------------------------------------------------


/*
 * If a font is not going to be used, free its structure.
 */
    void
gui_mch_free_font(font)
    GuiFont	font;
{
    printf("%s\n",__func__);  
}


    GuiFont
gui_mch_retain_font(GuiFont font)
{
    printf("%s\n",__func__);  
    return font;
}


/*
 * Get a font structure for highlighting.
 */
    GuiFont
gui_mch_get_font(char_u *name, int giveErrorIfMissing)
{
    printf("%s\n",__func__);  

    return NOFONT;
}


#if defined(FEAT_EVAL) || defined(PROTO)
/*
 * Return the name of font "font" in allocated memory.
 * TODO: use 'font' instead of 'name'?
 */
    char_u *
gui_mch_get_fontname(GuiFont font, char_u *name)
{
    return name ? vim_strsave(name) : NULL;
}
#endif


/*
 * Initialise vim to use the font with the given name.	Return FAIL if the font
 * could not be loaded, OK otherwise.
 */
    int
gui_mch_init_font(char_u *font_name, int fontset) {
    printf("%s\n",__func__);

    NSString * normalizedFontName = @"Courier";
    CGFloat normalizedFontSize = 14.0f;
    if (font_name != NULL) {
        normalizedFontName = [[NSString alloc] initWithUTF8String:(const char *)font_name];
    }
    CTFontRef rawFont = CTFontCreateWithName((CFStringRef)normalizedFontName, normalizedFontSize, &CGAffineTransformIdentity);
    [normalizedFontName release];

    
    CGRect boundingRect = CGRectZero;
    CGGlyph glyph = CTFontGetGlyphWithName(rawFont, (CFStringRef)@"0");
    CTFontGetBoundingRectsForGlyphs(rawFont, kCTFontHorizontalOrientation, &glyph, &boundingRect, 1);
    
    
    NSLog(@"Font bounding box for character 0 : %@", NSStringFromCGRect(boundingRect));
    NSLog(@"Ascent = %.2f", CTFontGetAscent(rawFont));
    NSLog(@"Computed height = %.2f", CTFontGetAscent(rawFont) + CTFontGetDescent(rawFont));
    NSLog(@"Leading = %.2f", CTFontGetLeading(rawFont));
    
    CGSize advances = CGSizeZero;
    
    CTFontGetAdvancesForGlyphs(rawFont, kCTFontHorizontalOrientation, &glyph, &advances, 1);
    NSLog(@"Advances = %@", NSStringFromCGSize(advances));

    gui.char_ascent = CTFontGetAscent(rawFont);
    gui.char_width = boundingRect.size.width;
    gui.char_height = boundingRect.size.height + 3.0f;
//    gui.char_height = CTFontGetAscent(rawFont) + CTFontGetDescent(rawFont);

    if (gui.norm_font != NULL) {
        CFRelease(gui.norm_font);
    }
    // Now let's rescale the font
    CGAffineTransform transform = CGAffineTransformMakeScale(boundingRect.size.width/advances.width, -1.0f);
    gui.norm_font = CTFontCreateCopyWithAttributes(rawFont,
                                                  normalizedFontSize,
                                                  &transform,
                                                  NULL);
    CFRelease(rawFont);
    
    return OK;
}


/*
 * Set the current text font.
 */
    void
gui_mch_set_font(GuiFont font)
{
    printf("%s\n",__func__);  
    // Font selection is done inside MacVim...nothing here to do.
}


// -- Scrollbars ------------------------------------------------------------

// NOTE: Even though scrollbar identifiers are 'long' we tacitly assume that
// they only use 32 bits (in particular when compiling for 64 bit).  This is
// justified since identifiers are generated from a 32 bit counter in
// gui_create_scrollbar().  However if that code changes we may be in trouble
// (if ever that many scrollbars are allocated...).  The reason behind this is
// that we pass scrollbar identifers over process boundaries so the width of
// the variable needs to be fixed (and why fix at 64 bit when only 32 are
// really used?).

    void
gui_mch_create_scrollbar(
	scrollbar_T *sb,
	int orient)	/* SBAR_VERT or SBAR_HORIZ */
{
    printf("%s\n",__func__);  
}


    void
gui_mch_destroy_scrollbar(scrollbar_T *sb)
{
    printf("%s\n",__func__);  
}


    void
gui_mch_enable_scrollbar(
	scrollbar_T	*sb,
	int		flag)
{
    printf("%s\n",__func__);  
}


    void
gui_mch_set_scrollbar_pos(
	scrollbar_T *sb,
	int x,
	int y,
	int w,
	int h)
{
    printf("%s\n",__func__);  
}


    void
gui_mch_set_scrollbar_thumb(
	scrollbar_T *sb,
	long val,
	long size,
	long max)
{
    printf("%s\n",__func__);  
}


// -- Cursor ----------------------------------------------------------------


/*
 * Draw a cursor without focus.
 */
    void
gui_mch_draw_hollow_cursor(guicolor_T color)
{
    printf("%s\n",__func__);  
    
    int w = 1;
    
#ifdef FEAT_MBYTE
    if (mb_lefthalve(gui.row, gui.col))
        w = 2;
#endif
    
    CGContextRef context = CGLayerGetContext(gui_ios.layer);
    CGContextSetStrokeColorWithColor(context, color);

    CGContextStrokeRect(context, CGRectMake(FILL_X(gui.col), FILL_Y(gui.row), w * gui.char_width, gui.char_height));
    [gui_ios.view_controller.view setNeedsDisplay];
}


/*
 * Draw part of a cursor, only w pixels wide, and h pixels high.
 */
    void
gui_mch_draw_part_cursor(int w, int h, guicolor_T color)
{
    printf("%s\n",__func__);
    CGContextRef context = CGLayerGetContext(gui_ios.layer);
    gui_mch_set_fg_color(color);
    
    CGRect rect;
    int    left;
    
#ifdef FEAT_RIGHTLEFT
    /* vertical line should be on the right of current point */
    if (CURSOR_BAR_RIGHT)
        left = FILL_X(gui.col + 1) - w;
    else
#endif
        left = FILL_X(gui.col);
    
    rect = CGRectMake(left, FILL_Y(gui.row), w, h);
    
    CGContextSetFillColorWithColor(context, color);
    CGContextFillRect(context, CGRectMake(left, FILL_Y(gui.row), (CGFloat)w, (CGFloat)h));
    [gui_ios.view_controller.view setNeedsDisplay];
}


/*
 * Cursor blink functions.
 *
 * This is a simple state machine:
 * BLINK_NONE	not blinking at all
 * BLINK_OFF	blinking, cursor is not shown
 * BLINK_ON blinking, cursor is shown
 */

    void
gui_mch_set_blinking(long wait, long on, long off)
{
    printf("%s\n",__func__);
    gui_ios.blink_wait = wait;
    gui_ios.blink_on   = on;
    gui_ios.blink_off  = off;
}


/*
 * Start the cursor blinking.  If it was already blinking, this restarts the
 * waiting time and shows the cursor.
 */
    void
gui_mch_start_blink(void)
{
    printf("%s\n",__func__);
    if (gui_ios.blink_timer != nil)
        [gui_ios.blink_timer invalidate];
    
    if (gui_ios.blink_wait && gui_ios.blink_on &&
        gui_ios.blink_off && gui.in_focus)
    {
        gui_ios.blink_timer = [NSTimer scheduledTimerWithTimeInterval: gui_ios.blink_wait / 1000.0
                                                               target: gui_ios.view_controller
                                                             selector: @selector(blinkCursorTimer:)
                                                             userInfo: nil
                                                              repeats: NO];
        gui_ios.blink_state = BLINK_ON;
        gui_update_cursor(TRUE, FALSE);
    }
}


/*
 * Stop the cursor blinking.  Show the cursor if it wasn't shown.
 */
    void
gui_mch_stop_blink(void)
{
    printf("%s\n",__func__);  
    [gui_ios.blink_timer invalidate];
    
//    if (gui_ios.blink_state == BLINK_OFF)
//        gui_update_cursor(TRUE, FALSE);
    
    gui_ios.blink_state = BLINK_NONE;
    gui_ios.blink_timer = nil;
}


// -- Mouse -----------------------------------------------------------------


/*
 * Get current mouse coordinates in text window.
 */
    void
gui_mch_getmouse(int *x, int *y)
{
    printf("%s\n",__func__);  
}


    void
gui_mch_setmouse(int x, int y)
{
    printf("%s\n",__func__);  
}


    void
mch_set_mouse_shape(int shape)
{
    printf("%s\n",__func__);  
}

     void
gui_mch_mousehide(int hide)
{
    printf("%s\n",__func__);  
}


// -- Clip ----
//
    void
clip_mch_request_selection(VimClipboard *cbd)
{
    printf("%s\n",__func__);  
}

    void
clip_mch_set_selection(VimClipboard *cbd)
{
    printf("%s\n",__func__);  
}

   void
clip_mch_lose_selection(VimClipboard *cbd)
{
    printf("%s\n",__func__);  
}

    int
clip_mch_own_selection(VimClipboard *cbd)
{
    printf("%s\n",__func__);  
    return OK;
}


// -- Input Method ----------------------------------------------------------

#if defined(USE_IM_CONTROL)

    void
im_set_position(int row, int col)
{
    printf("%s\n",__func__);  
}


    void
im_set_control(int enable)
{
    printf("%s\n",__func__);  
}


    void
im_set_active(int active)
{
    printf("%s\n",__func__);  
}


    int
im_get_status(void)
{
    printf("%s\n",__func__);  
}

#endif // defined(USE_IM_CONTROL)





// -- Unsorted --------------------------------------------------------------



/*
 * Adjust gui.char_height (after 'linespace' was changed).
 */
    int
gui_mch_adjust_charheight(void)
{
    printf("%s\n",__func__);  
    return OK;
}


    void
gui_mch_beep(void)
{
    printf("%s\n",__func__);  
}



#ifdef FEAT_BROWSE
/*
 * Pop open a file browser and return the file selected, in allocated memory,
 * or NULL if Cancel is hit.
 *  saving  - TRUE if the file will be saved to, FALSE if it will be opened.
 *  title   - Title message for the file browser dialog.
 *  dflt    - Default name of file.
 *  ext     - Default extension to be added to files without extensions.
 *  initdir - directory in which to open the browser (NULL = current dir)
 *  filter  - Filter for matched files to choose from.
 *  Has a format like this:
 *  "C Files (*.c)\0*.c\0"
 *  "All Files\0*.*\0\0"
 *  If these two strings were concatenated, then a choice of two file
 *  filters will be selectable to the user.  Then only matching files will
 *  be shown in the browser.  If NULL, the default allows all files.
 *
 *  *NOTE* - the filter string must be terminated with TWO nulls.
 */
    char_u *
gui_mch_browse(
    int saving,
    char_u *title,
    char_u *dflt,
    char_u *ext,
    char_u *initdir,
    char_u *filter)
{
    printf("%s\n",__func__);  
    return NULL;    
}
#endif /* FEAT_BROWSE */



    int
gui_mch_dialog(
    int		type,
    char_u	*title,
    char_u	*message,
    char_u	*buttons,
    int		dfltbutton,
    char_u	*textfield,
    int         ex_cmd)     // UNUSED
{
    printf("%s\n",__func__);
    return OK;
}


    void
gui_mch_flash(int msec)
{
    printf("%s\n",__func__);  
    
}


    guicolor_T
gui_mch_get_color(char_u *name)
{
    printf("%s\n",__func__);  
 
    static NSDictionary * sColorTable = nil;
    if (sColorTable == nil) {
        sColorTable = [[NSMutableDictionary alloc] init];

        char_u * rgbFilePath = expand_env_save((char_u *)"$VIMRUNTIME/rgb.txt");
        if (rgbFilePath == NULL) {
            return INVALCOLOR;
        }
        NSString* rgbFileContent = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:(const char *)rgbFilePath]
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
        vim_free(rgbFilePath);
        
        for (NSString * colorLine in [rgbFileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
            int pos = 0;
            int red = 0, green = 0, blue = 0;
            if (sscanf([colorLine UTF8String], "%d %d %d %n", &red, &green, &blue, &pos) == 3) {
                const char * colorName = [colorLine UTF8String] + pos;
                [(NSMutableDictionary *)sColorTable setObject:(id)([UIColor colorWithRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f].CGColor)
                                                       forKey:[[NSString stringWithUTF8String:colorName] lowercaseString]];
            }
        }
    }
    return [sColorTable objectForKey:[[NSString stringWithUTF8String:(const char *)name] lowercaseString]];
}


/*
 * Return the RGB value of a pixel as long.
 */
    long_u
gui_mch_get_rgb(guicolor_T pixel)
{
    printf("%s\n",__func__);  
    
    // This is only implemented so that vim can guess the correct value for
    // 'background' (which otherwise defaults to 'dark'); it is not used for
    // anything else (as far as I know).
    // The implementation is simple since colors are stored in an int as
    // "rrggbb".
    return pixel;
}


/*
 * Get the screen dimensions.
 * Allow 10 pixels for horizontal borders, 40 for vertical borders.
 * Is there no way to find out how wide the borders really are?
 * TODO: Add live udate of those value on suspend/resume.
 */
    void
gui_mch_get_screen_dimensions(int *screen_w, int *screen_h)
{
    printf("%s\n",__func__);
    CGSize appSize = [[UIScreen mainScreen] applicationFrame].size;
    *screen_w = appSize.width;
    *screen_h = appSize.height;
}


/*
 * Return OK if the key with the termcap name "name" is supported.
 */
    int
gui_mch_haskey(char_u *name)
{
    printf("%s\n",__func__);  
    return OK;
}


/*
 * Iconify the GUI window.
 */
    void
gui_mch_iconify(void)
{
    printf("%s\n",__func__);  
    
}


#if defined(FEAT_EVAL) || defined(PROTO)
/*
 * Bring the Vim window to the foreground.
 */
    void
gui_mch_set_foreground(void)
{
    printf("%s\n",__func__);  
}
#endif



    void
gui_mch_set_shellsize(
    int		width,
    int		height,
    int		min_width,
    int		min_height,
    int		base_width,
    int		base_height,
    int		direction)
{
//    printf("%s\n",__func__);
//    CGSize layerSize = CGLayerGetSize(gui_ios.layer);
//    gui_resize_shell(layerSize.width, layerSize.height);
}


/*
 * Set the position of the top left corner of the window to the given
 * coordinates.
 */
    void
gui_mch_set_winpos(int x, int y)
{
    printf("%s\n",__func__);  
}


/*
 * Get the position of the top left corner of the window.
 */
    int
gui_mch_get_winpos(int *x, int *y)
{
    printf("%s\n",__func__);  
    return OK;
}


    void
gui_mch_set_text_area_pos(int x, int y, int w, int h)
{
    printf("%s\n",__func__);  
}


#ifdef FEAT_TITLE
/*
 * Set the window title and icon.
 * (The icon is not taken care of).
 */
    void
gui_mch_settitle(char_u *title, char_u *icon)
{
    printf("%s\n",__func__);  
}
#endif


    void
gui_mch_toggle_tearoffs(int enable)
{
    printf("%s\n",__func__);  
}



    void
gui_mch_enter_fullscreen(int fuoptions_flags, guicolor_T bg)
{
    printf("%s\n",__func__);  
}


    void
gui_mch_leave_fullscreen()
{
    printf("%s\n",__func__);  
}


    void
gui_mch_fuopt_update()
{
    printf("%s\n",__func__);  
}





#if defined(FEAT_SIGN_ICONS)
    void
gui_mch_drawsign(int row, int col, int typenr)
{
    printf("%s\n",__func__);  
}

    void *
gui_mch_register_sign(char_u *signfile)
{
    printf("%s\n",__func__);  
   return NULL;
}

    void
gui_mch_destroy_sign(void *sign)
{
    printf("%s\n",__func__);  
}

#endif // FEAT_SIGN_ICONS



// -- Balloon Eval Support ---------------------------------------------------

#ifdef FEAT_BEVAL

    BalloonEval *
gui_mch_create_beval_area(target, mesg, mesgCB, clientData)
    void	*target;
    char_u	*mesg;
    void	(*mesgCB)__ARGS((BalloonEval *, int));
    void	*clientData;
{
    printf("%s\n",__func__);  

    return NULL;
}

    void
gui_mch_enable_beval_area(beval)
    BalloonEval	*beval;
{
    printf("%s\n",__func__);  
}

    void
gui_mch_disable_beval_area(beval)
    BalloonEval	*beval;
{
    printf("%s\n",__func__);  
}

/*
 * Show a balloon with "mesg".
 */
    void
gui_mch_post_balloon(beval, mesg)
    BalloonEval	*beval;
    char_u	*mesg;
{
    printf("%s\n",__func__);  
}

#endif // FEAT_BEVAL
