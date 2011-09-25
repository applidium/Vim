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
 * gui_macvim.m
 *
 * Hooks for the Vim gui code.  Mainly passes control on to MMBackend.
 */

#import "vim.h"
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#define GUI_IOS_CHAR_HEIGHT 8.0f
#define GUI_IOS_CHAR_WIDTH 4.0f

@interface VImAppDelegate : NSObject <UIApplicationDelegate> {
}
@end

@implementation VImAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self performSelector:@selector(_VImMain) withObject:nil afterDelay:0.1f];
    return YES;
}

- (void)_VImMain {
    char * argv[] = { "vim", "-c", "help" };
    VimMain(3, argv);
}
@end

@interface VImTextView : UIView <UIKeyInput> {
    CGLayerRef _cgLayer;
}
@property (nonatomic, readonly) CGLayerRef cgLayer;
@end

@implementation VImTextView
@synthesize cgLayer = _cgLayer;
- (void)drawRect:(CGRect)rect {
    NSLog(@"Drawing rect !");
    if (_cgLayer) {
//        CGContextDrawLayerInRect(UIGraphicsGetCurrentContext(), self.bounds, _cgLayer);
        CGContextRef context = UIGraphicsGetCurrentContext();
//        CGContextTranslateCTM(context, 0, 400.0f);
//        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawLayerAtPoint(context, CGPointMake(20.0f, 50.0f), _cgLayer);
    } else {
        [self willChangeValueForKey:@"cgLayer"];
        _cgLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), self.bounds.size, nil);
#define DEBUG_IOS_LAYER_ALIGNMENT 0
#if DEBUG_IOS_LAYER_ALIGNMENT
        CGContextRef context = CGLayerGetContext(_cgLayer);

        CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, 0.0f, 100.0f, 100.0f));
        CGContextSetFillColorWithColor(context, [UIColor greenColor].CGColor);
        CGContextFillRect(context, CGRectMake(100.0f, 0.0f, 100.0f, 100.0f));
        CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, 100.0f, 100.0f, 100.0f));
#endif
        [self didChangeValueForKey:@"cgLayer"];
    }
}
- (void)dealloc {
    if (_cgLayer) {
        CGLayerRelease(_cgLayer);
    }
    [super dealloc];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)hasText {
    return YES;
}

- (void)insertText:(NSString *)text {
    NSLog(@"Inserting %@", text);
    add_to_input_buf([text UTF8String], [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    [self setNeedsDisplay];
}

- (void)deleteBackward {
    NSLog(@"Delete backward");
}


@end

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"VImAppDelegate");
    [pool release];
    return retVal;
}

struct {
    UIWindow * window;
    CGLayerRef layer;
} gui_ios;


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


/* Called directly after forking (even if we didn't fork). */
    void
gui_macvim_after_fork_init()
{
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

    UIWindow * window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.backgroundColor = [UIColor blueColor];
    VImTextView * textView = [[VImTextView alloc] initWithFrame:window.bounds];
    textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [window addSubview:textView];
    [textView release];
    [textView becomeFirstResponder];
    gui_ios.window = window;

//
//    gui_mac_info("%s", exe_name);
//    
//    gui_mac.app_pool = [NSAutoreleasePool new];
//    
//    [NSApplication sharedApplication];
//    
//    gui_mac.app_delegate = [VimAppController new];
//    [NSApp setDelegate: gui_mac.app_delegate];
//    
//    [NSApp setMainMenu: [[NSMenu new] autorelease]];
//    gui_mac_set_application_menu();
//    
//    gui.char_width = 0;
//    gui.char_height = 0;
//    gui.char_ascent = 0;
//    gui.num_rows = 24;
//    gui.num_cols = 80;
//    gui.tabline_height = 22;
//    gui.in_focus = TRUE;
//    
//    gui.norm_pixel = 0x00000000;
//    gui.back_pixel = 0x00FFFFFF;
//    set_normal_colors();
//    
//    gui_check_colors();
//    gui.def_norm_pixel = gui.norm_pixel;
//    gui.def_back_pixel = gui.back_pixel;
//    
//    /* Get the colors for the highlight groups (gui_check_colors() might have
//     * changed them) */
//    highlight_gui_started();
//    
//#ifdef FEAT_MENU
//    gui.menu_height = 0;
//#endif
//    gui.scrollbar_height = gui.scrollbar_width = [VIMScroller scrollerWidth];
//    gui.border_offset = gui.border_width = 2;
//    
//    gui_mac.current_window = nil;
//    gui_mac.input_received = NO;
//    gui_mac.initialized    = NO;
//    gui_mac.showing_tabline = NO;
//    gui_mac.selecting_tab   = NO;
//    gui_mac.window_at_front = NO;
//    gui_mac.max_ops         = VIM_MAX_DRAW_OP_QUEUE;
//    gui_mac.ops             = calloc(gui_mac.max_ops,
//                                     sizeof(struct gui_mac_drawing_op));
//    gui_mac.queued_ops      = 0;
//    
//    gui_mac.last_im_source = NULL;
//    // get an ASCII source for use when IM is deactivated (by Vim)
//    gui_mac.ascii_im_source = TISCopyCurrentKeyboardInputSource();
//    
//    CFBooleanRef isASCIICapable =
//    TISGetInputSourceProperty(gui_mac.ascii_im_source,
//                              kTISPropertyInputSourceIsASCIICapable);
//    if (! CFBooleanGetValue(isASCIICapable))
//    {
//        CFRelease(gui_mac.ascii_im_source);
//        gui_mac.ascii_im_source = TISCopyCurrentASCIICapableKeyboardInputSource();
//    }
//    
//    return OK;
//
//    
//    
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
    static CFAbsoluteTime lastTime = 0;

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
    
}


/*
 * Clear a rectangular region of the screen from text pos (row1, col1) to
 * (row2, col2) inclusive.
 */
    void
gui_mch_clear_block(int row1, int col1, int row2, int col2)
{
    printf("%s\n",__func__);  
}


/*
 * Delete the given number of lines from the given row, scrolling up any
 * text further down within the scroll region.
 */
    void
gui_mch_delete_lines(int row, int num_lines)
{
    printf("%s\n",__func__);  
}


void gui_mch_draw_string(int row, int col, char_u *s, int len, int flags) {
    printf("%s\n",__func__);
    printf("===========================\n");
    printf("Drawing at %d x %d : |%.*s|\n", col, row, len, s);
    printf("===========================\n");
    VImTextView * textView = (VImTextView *)[[gui_ios.window subviews] lastObject];
    CGLayerRef layer = textView.cgLayer;
    
    CGContextRef context = CGLayerGetContext(layer);
    CGContextSelectFont(context, "Courier", GUI_IOS_CHAR_HEIGHT, kCGEncodingMacRoman);
    CGContextSetCharacterSpacing(context, 0.0f); // FIXME : maybe 0 isnt right. Seems to look better though
    CGContextSetTextDrawingMode(context, kCGTextFill);
    
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 1.0, 1.0);

#define USE_CORE_TEXT 0
#if USE_CORE_TEXT
    CTFontRef font = CTFontCreateWithName(@"Courier", 12.0f, &CGAffineTransformIdentity);
    CFStringRef string = [[NSString alloc] initWithBytes:s length:len encoding:NSUTF8StringEncoding];
    
    // Initialize string, font, and context
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { font };
    CFDictionaryRef attributes = [NSDictionary dictionaryWithObject:font forKey:kCTFontAttributeName];
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, string, attributes);
    CFRelease(string);
    CFRelease(attributes);
    CTLineRef line = CTLineCreateWithAttributedString(attrString);
    // Set text position and draw the line into the graphics context
    CGContextSetTextPosition(context, 12.0 * col, 12.0 * row);
    CTLineDraw(line, context);
    CFRelease(line);
#else
    CGContextSetRGBFillColor(context, 0.2, 0.2, 0.2, 1.0);
    CGContextFillRect(context, CGRectMake(GUI_IOS_CHAR_WIDTH*col, GUI_IOS_CHAR_HEIGHT*row, GUI_IOS_CHAR_WIDTH*len, GUI_IOS_CHAR_HEIGHT));
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0, -1.0));
    
    NSString * string = [[NSString alloc] initWithBytes:s length:len encoding:NSUTF8StringEncoding];
    NSLog(@"Showing : |%@|", string);
    char * romanBytes = [string cStringUsingEncoding:NSMacOSRomanStringEncoding];
    int length = [string lengthOfBytesUsingEncoding:NSMacOSRomanStringEncoding];

    
    CGContextShowTextAtPoint(context, GUI_IOS_CHAR_WIDTH * col, GUI_IOS_CHAR_HEIGHT * row, romanBytes, length); 
    [string release];
#endif
    
    [textView setNeedsDisplay];
/*
    
    CGLayerCreateWithContext r
    NSGraphicsContext
    UIGraphicsPopContext()
    UIGraphicsGetCurrentContext
    CGContextRef
    UIGraphicsBeginImageContext
    [gui_ios.window lockFocus];
 */
}


/*
 * Insert the given number of lines before the given row, scrolling down any
 * following text within the scroll region.
 */
    void
gui_mch_insert_lines(int row, int num_lines)
{
    printf("%s\n",__func__);  
}


/*
 * Set the current text foreground color.
 */
    void
gui_mch_set_fg_color(guicolor_T color)
{
    printf("%s\n",__func__);  
}


/*
 * Set the current text background color.
 */
    void
gui_mch_set_bg_color(guicolor_T color)
{
    printf("%s\n",__func__);  
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
    void
gui_mch_def_colors()
{
    printf("%s\n",__func__);  
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
gui_mch_invert_rectangle(int r, int c, int nr, int nc, int invert)
{
    printf("%s\n",__func__);  
}



// -- Tabline ---------------------------------------------------------------


/*
 * Set the current tab to "nr".  First tab is 1.
 */
    void
gui_mch_set_curtab(int nr)
{
    printf("%s\n",__func__);  
}


/*
 * Return TRUE when tabline is displayed.
 */
    int
gui_mch_showing_tabline(void)
{
    printf("%s\n",__func__);  
    return TRUE;
}

/*
 * Update the labels of the tabline.
 */
    void
gui_mch_update_tabline(void)
{
    printf("%s\n",__func__);  
}

/*
 * Show or hide the tabline.
 */
    void
gui_mch_show_tabline(int showit)
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
gui_mch_init_font(char_u *font_name, int fontset)
{
    printf("%s\n",__func__);  
    
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


/*
 * Return GuiFont in allocated memory.  The caller must free it using
 * gui_mch_free_font().
 */
    GuiFont
gui_macvim_font_with_name(char_u *name)
{
    printf("%s\n",__func__);  
    return NOFONT;
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
}


/*
 * Draw part of a cursor, only w pixels wide, and h pixels high.
 */
    void
gui_mch_draw_part_cursor(int w, int h, guicolor_T color)
{
    printf("%s\n",__func__);  
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
}


/*
 * Start the cursor blinking.  If it was already blinking, this restarts the
 * waiting time and shows the cursor.
 */
    void
gui_mch_start_blink(void)
{
    printf("%s\n",__func__);  
}


/*
 * Stop the cursor blinking.  Show the cursor if it wasn't shown.
 */
    void
gui_mch_stop_blink(void)
{
    printf("%s\n",__func__);  
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




// -- Find & Replace dialog -------------------------------------------------

#ifdef FIND_REPLACE_DIALOG

    static void
macvim_find_and_replace(char_u *arg, BOOL replace)
{
    printf("%s\n",__func__);  
}

    void
gui_mch_find_dialog(exarg_T *eap)
{
    printf("%s\n",__func__);  
}

    void
gui_mch_replace_dialog(exarg_T *eap)
{
    printf("%s\n",__func__);  
}

#endif // FIND_REPLACE_DIALOG




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
    return NULL;
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
    printf("%s\n",__func__);  
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


    void
gui_macvim_update_modified_flag()
{
    printf("%s\n",__func__);  
}

/*
 * Add search pattern 'pat' to the OS X find pasteboard.  This allows other
 * apps access the last pattern searched for (hitting <D-g> in another app will
 * initiate a search for the same pattern).
 */
    void
gui_macvim_add_to_find_pboard(char_u *pat)
{
    printf("%s\n",__func__);  
}

    void
gui_macvim_set_antialias(int antialias)
{
    printf("%s\n",__func__);  
}


    void
gui_macvim_wait_for_startup()
{
    printf("%s\n",__func__);  
}

void gui_macvim_get_window_layout(int *count, int *layout)
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
