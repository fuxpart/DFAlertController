//
//  DFAlertController.h
//  DFAlertController
//
//  Created by fuxp on 2017/3/8.
//  Copyright © 2017年 fuxp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFAlertController;
@class DFAlertAction;

typedef NS_ENUM(NSInteger, DFAlertActionStyle) {
    DFAlertActionStyleNormal,
    DFAlertActionStyleDestructive
};

NS_ASSUME_NONNULL_BEGIN

typedef void (^DFAlertActionHandler) (DFAlertAction *action);

@interface DFAlertAction : NSObject

/**
 Create and return an action with the specified title and behavior. Actions are enabled by default when you create them.

 @param title The text to use for the button title.
 @param style Additional styling information to apply to the action.
 @param handler A block to execute when the user selects the action. This block has no return value and takes the selected action object as its only parameter.
 @return A new action object.
 */
+ (instancetype)actionWithTitle:(NSString *)title style:(DFAlertActionStyle)style handler:(nullable DFAlertActionHandler)handler;
+ (instancetype)actionWithTitle:(NSString *)title handler:(nullable DFAlertActionHandler)handler;
- (instancetype)init NS_UNAVAILABLE;

/**
 The style that is applied to the action.
 */

@property (nonatomic, assign, readonly) DFAlertActionStyle style;

/**
 The controller hold the action.
 */
@property (nonatomic, weak, readonly, nullable) DFAlertController *controller;

/**
 Title of the action.
 */
@property (nonatomic, copy, readonly) NSString *title;

/**
 Color of the title.
 */
@property (nonatomic, strong, nullable) UIColor *titleColor;

/**
 A Boolean value indicating whether the action is currently enabled. The default value of this property is YES.
 */
@property (nonatomic, assign, getter=isEnabled) BOOL enable;

@end

@interface DFAlertController : NSObject

/**
 Creates and returns a alert controller for displaying an alert to the user.
 After creating the alert controller, configure any actions that you want the user to be able to perform by calling the `addAction:` method one or more times. You may also configure one or more text fields to display in addition to the actions.

 @param title The title of the alert.
 @param message Additional details about the reason for the alert, can be a string, image or any other object.
 @return An initialized alert controller object.
 */
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable id)message;
- (instancetype)init NS_UNAVAILABLE;

/**
 Attaches an action object to the alert. If your alert has multiple actions, the order in which you add those actions determines their order in the resulting alert.

 @param action The action object to display as part of the alert.
 */
- (void)addAction:(DFAlertAction *)action;

/**
 The actions that the user can take in response to the alert.
 */
@property (nonatomic, strong, readonly) NSArray <DFAlertAction *>*actions;

/**
 Dismisses the alert. Use this method when you need to explicitly dismiss the alert.
 
 @param index The index of the action. If you just want to dismiss the alert without doing anything, pass -1.
 */
- (void)dismissWithHandleActionIndex:(NSUInteger)index;

/**
 Adds a text field to an alert. Calling this method adds an editable text field to the alert. You can call this method more than once to add additional text fields.

 @param handler A block for configuring the text field prior to displaying the alert. This block has no return value and takes a single parameter corresponding to the text field object. Use that parameter to change the text field properties. Note that change the frame of the text field will has no effect.
 */
- (void)addTextFieldWithConfigurationHandler:(void (^ __nullable)(UITextField *textField))handler;

/**
 The array of text fields displayed by the alert.
 */
@property (nonatomic, strong, readonly, nullable) NSArray <UITextField *>*textFields;

/**
 Touch to end text field input, NO for default.
 */
@property (nonatomic, assign) BOOL touchToEndEditing;

/**
 Set background color of the alert.
 */
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/**
 Show the alert.
 */
- (void)show;

@end

NS_ASSUME_NONNULL_END
