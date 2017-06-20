//
//  KeyboardEventManager.h
//  Vim
//
//  Created by peng hao on 2017/6/19.
//
//

#import <Foundation/Foundation.h>

#define ESC_CODE 0x29

typedef void(^KeyBoardObserverBlock)(BOOL);
@interface KeyboardEventManager : NSObject
@property(nonatomic, readonly) BOOL isLeftCommandDown;  //227
@property(nonatomic, readonly) BOOL isLeftOptionDown;   //226
@property(nonatomic, readonly) BOOL isLeftShiftDown;    //225
@property(nonatomic, readonly) BOOL isLeftCtrlDown;     //224

+(instancetype) sharedKeyboardEventManager;
- (void) handleKey:(NSInteger) keyCode isPressDown:(BOOL) down;

- (void) addObserver:(NSInteger) keyCode block:(KeyBoardObserverBlock) block;
@end
