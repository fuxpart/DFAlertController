//
//  DFAlertController.m
//  DFAlertController
//
//  Created by fuxp on 2017/3/8.
//  Copyright © 2017年 fuxp. All rights reserved.
//

#import "DFAlertController.h"

#define ALERT_WIDTH  270
#define MARGIN  20
#define TEXTFIELD_HEIGHT 30
#define BUTTON_HEIGHT 50

@class DFAlertActionButton;

@interface DFAlertAction ()
{
@public
    DFAlertActionButton *_button;
    DFAlertController * __weak _controller;
    DFAlertActionHandler _handler;
}

- (void)handleButtonAction;

@end

@interface DFAlertInnerView : UIVisualEffectView
{
    UILabel *_titleLable;
    UILabel *_messageLabel;
    NSMutableArray *_buttons;
    NSMutableArray *_customConstraints;
@public
    UIScrollView *_bgScrollView;
    NSMutableArray *_textFields;
    NSLayoutConstraint *_constraintHeight;
    CGFloat _freeVerticalSpace;
}
- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSAttributedString *)message;
- (void)addButtonWithAction:(DFAlertAction *)action;
- (void)addTextField:(UITextField *)textField;
@end

@interface DFAlertViewController : UIViewController
{
    NSLayoutConstraint *_constraintCenterX;
    NSLayoutConstraint *_constraintTop;
    CGFloat _keyboardY;
    BOOL _keyboardWillShow;
@public
    DFAlertInnerView *_innerView;
    BOOL _touchToEnding;
}
@end

typedef NS_OPTIONS(NSInteger, DFAlertActionButtonBoardLineStyle) {
    DFAlertActionButtonBoardLineStyleNone = 0,
    DFAlertActionButtonBoardLineStyleLeft = 1 << 0,
    DFAlertActionButtonBoardLineStyleTop = 1 << 1,
    DFAlertActionButtonBoardLineStyleRight = 1 << 2,
    DFAlertActionButtonBoardLineStyleBottom = 1 << 3
};

@interface DFAlertActionButton : UIButton
{
    UIColor *_color;
}
- (instancetype)initWithAction:(DFAlertAction *)action;
@property (nonatomic, assign) DFAlertActionButtonBoardLineStyle boardLineStyle;

@end

@implementation DFAlertActionButton

- (instancetype)initWithAction:(DFAlertAction *)action {
    self = [super init];
    if (self) {
        _color = [UIColor colorWithWhite:0.5 alpha:0.5];
        [self setTitle:action.title forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:17];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.5;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self setTitleColor:action.titleColor forState:UIControlStateNormal];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.enabled = action.enable;
        [self addTarget:action action:@selector(handleButtonAction) forControlEvents:UIControlEventTouchUpInside];
        action->_button = self;
    }
    return self;
}

- (void)setBoardLineStyle:(DFAlertActionButtonBoardLineStyle)boardLineStyle {
    _boardLineStyle = boardLineStyle;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1 / [UIScreen mainScreen].scale);
    CGContextSetStrokeColorWithColor(context, _color.CGColor);
    if (_boardLineStyle & DFAlertActionButtonBoardLineStyleLeft) {
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, 0, rect.size.height);
    }
    if (_boardLineStyle & DFAlertActionButtonBoardLineStyleTop) {
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, rect.size.width, 0);
    }
    if (_boardLineStyle & DFAlertActionButtonBoardLineStyleRight) {
        CGContextMoveToPoint(context, rect.size.width, 0);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    }
    if (_boardLineStyle & DFAlertActionButtonBoardLineStyleBottom) {
        CGContextMoveToPoint(context, 0, rect.size.height);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    }
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.backgroundColor = _color;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

@end

@interface DFAlertController ()
- (void)dismiss;
@end

@implementation DFAlertInnerView

- (instancetype)initWithTitle:(NSString *)title message:(NSAttributedString *)message {
    self = [super initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    if (self) {
        self.layer.cornerRadius = 15;
        self.layer.masksToBounds = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _customConstraints = [NSMutableArray array];
        
        _bgScrollView = [[UIScrollView alloc]init];
        _bgScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_bgScrollView];
        
        _titleLable = [[UILabel alloc]init];
        _titleLable.font = [UIFont boldSystemFontOfSize:17];
        _titleLable.backgroundColor = [UIColor clearColor];
        _titleLable.textColor = [UIColor blackColor];
        _titleLable.textAlignment = NSTextAlignmentCenter;
        _titleLable.numberOfLines = 0;
        _titleLable.text = title;
        _titleLable.translatesAutoresizingMaskIntoConstraints = NO;
        [_bgScrollView addSubview:_titleLable];
        
        _messageLabel = [[UILabel alloc]init];
        _messageLabel.numberOfLines = 0;
        _messageLabel.userInteractionEnabled = YES;
        _messageLabel.attributedText = message;
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_bgScrollView addSubview:_messageLabel];
        
        _buttons = [NSMutableArray array];
    }
    return self;
}

- (void)addButtonWithAction:(DFAlertAction *)action {
    DFAlertActionButton *button = [[DFAlertActionButton alloc]initWithAction:action];
    [_bgScrollView addSubview:button];
    [_buttons addObject:button];
}

- (void)addTextField:(UITextField *)textField {
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [_bgScrollView addSubview:textField];
    if (!_textFields) {
        _textFields = [NSMutableArray array];
    }
    [_textFields addObject:textField];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSAssert(_buttons.count, @"We should have at least one button!");
    for (NSLayoutConstraint *constraint in _customConstraints) {
        constraint.active = NO;
    }
    [_customConstraints removeAllObjects];
    NSLayoutConstraint *widthC = [NSLayoutConstraint constraintWithItem:self
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1
                                                               constant:ALERT_WIDTH];
    [self activeConstraint:widthC];
    //scroll view
    NSArray *scrollHCs = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_bgScrollView]|"
                                                              options:0
                                                              metrics:nil
                                                                views:NSDictionaryOfVariableBindings(_bgScrollView)];
    [self activeConstraints:scrollHCs];
    
    NSArray *scrollVCs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_bgScrollView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_bgScrollView)];
    [self activeConstraints:scrollVCs];
    //title
    CGRect titleRect = [_titleLable.text boundingRectWithSize:CGSizeMake(ALERT_WIDTH - 2 * MARGIN, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   attributes:@{NSFontAttributeName : _titleLable.font}
                                                      context:nil];
    CGFloat titleHeight = ceil(titleRect.size.height);
    CGRect messageRect = [_messageLabel.attributedText boundingRectWithSize:CGSizeMake(ALERT_WIDTH - 2 * MARGIN, CGFLOAT_MAX)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                    context:nil];
    //message
    CGFloat messageHeight = ceil(messageRect.size.height);
    NSArray *titleHCs = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-MARGIN-[_titleLable(labelWidth)]-MARGIN-|"
                                                                options:0
                                                                metrics:@{@"MARGIN" : @(MARGIN),
                                                                          @"labelWidth" : @(ALERT_WIDTH - 2 * MARGIN)}
                                                                  views:NSDictionaryOfVariableBindings(_titleLable)];
    NSArray *messageHCs = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-MARGIN-[_messageLabel(labelWidth)]-MARGIN-|"
                                                                  options:0
                                                                  metrics:@{@"MARGIN" : @(MARGIN),
                                                                            @"labelWidth" : @(ALERT_WIDTH - 2 * MARGIN)}
                                                                    views:NSDictionaryOfVariableBindings(_messageLabel)];
    NSArray *textVCs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-MARGIN-[_titleLable(titleHeight)]-5-[_messageLabel(messageHeight)]"
                                                               options:0
                                                               metrics:@{@"MARGIN" : @(MARGIN),
                                                                         @"titleHeight" : @(titleHeight),
                                                                         @"messageHeight" : @(messageHeight)}
                                                                 views:NSDictionaryOfVariableBindings(_titleLable, _messageLabel)];
    [self activeConstraints:titleHCs];
    [self activeConstraints:messageHCs];
    [self activeConstraints:textVCs];
    
    CGFloat height = MARGIN + titleHeight + 5 + messageHeight + MARGIN;
    //text field
    NSInteger textFieldCount = _textFields.count;
    for (NSInteger i = 0; i < textFieldCount; i++) {
        UITextField *textField = _textFields[i];
        NSArray *hcs = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-MARGIN-[textField]-MARGIN-|"
                                                               options:0
                                                               metrics:@{@"MARGIN" : @(MARGIN)}
                                                                 views:NSDictionaryOfVariableBindings(textField)];
        [self activeConstraints:hcs];
        NSArray *vcs;
        if (0 == i) {
            vcs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_messageLabel]-MARGIN-[textField(TEXTFIELD_HEIGHT)]"
                                                          options:0
                                                          metrics:@{@"MARGIN" : @(MARGIN),
                                                                    @"TEXTFIELD_HEIGHT" : @(TEXTFIELD_HEIGHT)}
                                                            views:NSDictionaryOfVariableBindings(_messageLabel, textField)];
        } else {
            UITextField *last = _textFields[i - 1];
            vcs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[last]-1-[textField(TEXTFIELD_HEIGHT)]"
                                                          options:0
                                                          metrics:@{@"TEXTFIELD_HEIGHT" : @(TEXTFIELD_HEIGHT)}
                                                            views:NSDictionaryOfVariableBindings(last, textField)];
        }
        [self activeConstraints:vcs];
    }
    if (textFieldCount > 0) {
        height += 30 * textFieldCount + textFieldCount - 1 + MARGIN;
    }
    //button
    NSInteger buttonCount = _buttons.count;
    if (2 == buttonCount) {
        DFAlertActionButton *left = _buttons[0];
        DFAlertActionButton *right = _buttons[1];
        CGFloat width1 = ceil([[left titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : left.titleLabel.font}].width);
        CGFloat width2 = ceil([[right titleForState:UIControlStateNormal] sizeWithAttributes:@{NSFontAttributeName : right.titleLabel.font}].width);
        if (width1 > ALERT_WIDTH / 2 || width2 > ALERT_WIDTH) { //one of the buttons is too wide
            goto vertical;
        }
        left.boardLineStyle = DFAlertActionButtonBoardLineStyleTop;
        right.boardLineStyle = DFAlertActionButtonBoardLineStyleLeft | DFAlertActionButtonBoardLineStyleTop;
        UIView *top;
        if (_textFields.count > 0) {
            top = _textFields.lastObject;
        } else {
            top = _messageLabel;
        }
        NSArray *hc = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[left(width)][right(width)]|"
                                                              options:0
                                                              metrics:@{@"width" : @(ALERT_WIDTH / 2)}
                                                                views:NSDictionaryOfVariableBindings(left, right)];
        [self activeConstraints:hc];
        NSArray *vl = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[top]-MARGIN-[left(height)]|"
                                                              options:0
                                                              metrics:@{@"MARGIN" : @(MARGIN),
                                                                        @"height" : @(BUTTON_HEIGHT)}
                                                                views:NSDictionaryOfVariableBindings(top, left)];
        NSArray *vr = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[top]-MARGIN-[right(height)]|"
                                                              options:0
                                                              metrics:@{@"MARGIN" : @(MARGIN),
                                                                        @"height" : @(BUTTON_HEIGHT)}
                                                                views:NSDictionaryOfVariableBindings(top, right)];
        [self activeConstraints:vl];
        [self activeConstraints:vr];
        height += BUTTON_HEIGHT;
    } else {
    vertical:
        for (NSInteger i = 0; i < buttonCount; i++) {
            DFAlertActionButton *button = _buttons[i];
            button.boardLineStyle = DFAlertActionButtonBoardLineStyleTop;
            NSArray *hc = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(button)];
            [self activeConstraints:hc];
            UIView *last;
            NSArray *vc;
            if (0 == i) {
                if (_textFields.count > 0) {
                    last = [_textFields lastObject];
                } else {
                    last = _messageLabel;
                }
                vc = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[last]-MARGIN-[button(height)]"
                                                             options:0
                                                             metrics:@{@"MARGIN" : @(MARGIN),
                                                                       @"height" : @(BUTTON_HEIGHT)}
                                                               views:NSDictionaryOfVariableBindings(last, button)];
            } else {
                last = _buttons[i - 1];
                vc = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[last][button(height)]"
                                                             options:0
                                                             metrics:@{@"height" : @(BUTTON_HEIGHT)}
                                                               views:NSDictionaryOfVariableBindings(last, button)];
            }
            
            [self activeConstraints:vc];
            height += BUTTON_HEIGHT;
        }
    }
    DFAlertActionButton *last = [_buttons lastObject];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:last
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_bgScrollView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0];
    [self activeConstraint:bottom];
    if (height > _freeVerticalSpace) {
        height = _freeVerticalSpace;
    }
    _constraintHeight = [NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:height];
    [self activeConstraint:_constraintHeight];
    
    for (UITextField *textField in _textFields) {
        if (textField.isFirstResponder) {
            [_bgScrollView scrollRectToVisible:textField.frame animated:YES];
            break;
        }
    }
}

- (void)activeConstraint:(NSLayoutConstraint *)constraint {
    constraint.active = YES;
    [_customConstraints addObject:constraint];
}

- (void)activeConstraints:(NSArray *)constraints {
    [NSLayoutConstraint activateConstraints:constraints];
    [_customConstraints addObjectsFromArray:constraints];
}
@end

@implementation DFAlertViewController

- (instancetype)initWithTitle:(NSString *)title message:(nullable NSAttributedString *)message {
    self = [super init];
    if (self) {
        _innerView = [[DFAlertInnerView alloc]initWithTitle:title message:message];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    [self.view addSubview:_innerView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(endTextFieldInput)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _constraintCenterX.active = NO;
    _constraintCenterX = [NSLayoutConstraint constraintWithItem:_innerView
                                                      attribute:NSLayoutAttributeCenterX
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.view
                                                      attribute:NSLayoutAttributeCenterX
                                                     multiplier:1
                                                       constant:0];
    _constraintCenterX.active = YES;
    _innerView->_freeVerticalSpace = _keyboardWillShow ? _keyboardY : [UIScreen mainScreen].bounds.size.height;
    CGFloat constant = 0;
    if (_innerView->_freeVerticalSpace > _innerView->_constraintHeight.constant) {
        if (_innerView->_bgScrollView.contentSize.height > _innerView->_constraintHeight.constant) {
            [_innerView setNeedsLayout];
            [_innerView layoutIfNeeded];
        }
        constant = (_innerView->_freeVerticalSpace - _innerView->_constraintHeight.constant) / 2;
    } else {
        [_innerView setNeedsLayout];
        [_innerView layoutIfNeeded];
    }
    _constraintTop.active = NO;
    _constraintTop = [NSLayoutConstraint constraintWithItem:_innerView
                                                      attribute:NSLayoutAttributeTop
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.view
                                                      attribute:NSLayoutAttributeTop
                                                     multiplier:1
                                                       constant:constant];
    _constraintTop.active = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateLayourWithNotification:(NSNotification *)notification {
    _keyboardY = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    [self.view setNeedsLayout];
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [_innerView setNeedsLayout];
        [_innerView layoutIfNeeded];
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    _keyboardWillShow = YES;
    [self updateLayourWithNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    _keyboardWillShow = NO;
    [self updateLayourWithNotification:notification];
}

- (void)endTextFieldInput {
    if (_touchToEnding) {
        for (UITextField *textField in _innerView->_textFields) {
            [textField resignFirstResponder];
        }
    }
}

@end

@implementation DFAlertAction

+ (instancetype)actionWithTitle:(NSString *)title handler:(DFAlertActionHandler)handler {
    return [[[self class] alloc] initWithTitle:title style:DFAlertActionStyleNormal handler:handler];
}

+ (instancetype)actionWithTitle:(NSString *)title style:(DFAlertActionStyle)style handler:(DFAlertActionHandler)handler {
    return [[[self class] alloc] initWithTitle:title style:style handler:handler];
}

- (instancetype)initWithTitle:(NSString *)title style:(DFAlertActionStyle)style handler:(DFAlertActionHandler)handler {
    self = [super init];
    if (self) {
        _style = style;
        _title = title;
        _handler = [handler copy];
        if (DFAlertActionStyleDestructive == style) {
            _titleColor = [UIColor redColor];
        } else {
            _titleColor = [UIColor blackColor];
        }
        _enable = YES;
    }
    return self;
}

- (void)handleButtonAction {
    if (_handler) {
        _handler(self);
    }
    [_controller dismiss];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    _button.enabled = enable;
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    [_button setTitleColor:titleColor forState:UIControlStateNormal];
}

@end

static NSMutableArray *__holder__;  //hold the alerts to avoid release.

@implementation DFAlertController
{
    NSMutableArray *_actions;
    @public
    UIWindow *_window;
    DFAlertViewController *_viewController; //Only UIViewController can handle rotations.
}

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(id)message {
    NSAttributedString *attributedMessage;
    if (!message || [message isKindOfClass:[NSAttributedString class]]) {
        attributedMessage = message;
    } else if ([message isKindOfClass:[UIImage class]]) {
        UIImage *image = (UIImage *)message;
        //We use NSAttributedString to display the image but not UIImageView.
        NSTextAttachment *attachment = [[NSTextAttachment alloc]init];
        attachment.image = image;
        CGFloat factor = 1;
        if (image.size.width > (ALERT_WIDTH - 2 * MARGIN)) {
            factor = (ALERT_WIDTH - 2 * MARGIN) / image.size.width;
        }
        attachment.bounds = CGRectMake(0, 0, image.size.width * factor, image.size.height * factor);
        NSMutableAttributedString *mutableMessage = [[NSMutableAttributedString alloc]init];
        [mutableMessage appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc]init];
        ps.alignment = NSTextAlignmentCenter;   //center
        [mutableMessage addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, attributedMessage.length)];
        attributedMessage = mutableMessage;
    } else {
        NSString *plainMessage;
        if ([message isKindOfClass:[NSString class]]) {
            plainMessage = message;
        } else if ([message isKindOfClass:[NSError class]]) {
            plainMessage = [message localizedDescription];
        } else {
            plainMessage = [message description];
        }
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        attributedMessage = [[NSAttributedString alloc]initWithString:message
                                                           attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18],
                                                                        NSForegroundColorAttributeName : [UIColor colorWithWhite:0.6 alpha:1],
                                                                        NSParagraphStyleAttributeName : paragraphStyle}];
    }
    return [[[self class] alloc] initWithTitle:title message:attributedMessage];
}

- (instancetype)initWithTitle:(NSString *)title message:(NSAttributedString *)message {
    self = [super init];
    if (self) {
#if DEBUG
        if (!title.length && !message.length) {
            NSLog(@"Warning: either title or message should be set.");
        }
        if (![NSThread currentThread].isMainThread) {
            NSLog(@"Warning: an alert should be created and popped in main thread.");
        }
#endif
        _viewController = [[DFAlertViewController alloc]initWithTitle:title message:message];
        _window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _window.windowLevel = UIWindowLevelAlert - 1;
        _window.rootViewController = _viewController;
        _actions = [NSMutableArray array];
    }
    return self;
}

- (void)addAction:(DFAlertAction *)action {
    action->_controller = self;
    [_actions addObject:action];
    [_viewController->_innerView addButtonWithAction:action];
}

- (void)dismissWithHandleActionIndex:(NSUInteger)index {
    if (index >= _actions.count) {
        [self dismiss];
    } else {
        DFAlertAction *action = _actions[index];
        [action handleButtonAction];
    }
}

- (void)addTextFieldWithConfigurationHandler:(void (^)(UITextField *))handler {
    UITextField *textField = [[UITextField alloc]init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    if (handler) {
        handler(textField);
    }
    [_viewController->_innerView addTextField:textField];
}

- (NSArray *)textFields {
    return [_viewController->_innerView->_textFields copy];
}

- (void)setTouchToEndEditing:(BOOL)touchToEndEditing {
    _touchToEndEditing = touchToEndEditing;
    _viewController->_touchToEnding = touchToEndEditing;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    _viewController->_innerView.backgroundColor = backgroundColor;
}

- (void)show {
    if (!__holder__) {
        __holder__ = [NSMutableArray array];
    }
    [__holder__ addObject:self];
    if (__holder__.count > 1) {
        return;
    }
    [self showAlert];
}

- (void)showAlert {
    _window.hidden = NO;
    _viewController.view.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        _viewController.view.alpha = 1;
    }];
    _viewController->_innerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:25 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _viewController->_innerView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss {
    [UIView animateWithDuration:0.25 animations:^{
        _viewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        _window.hidden = YES;
        _window = nil;
        if (__holder__.count > 1) {
            DFAlertController *alert = __holder__[1];
            [alert showAlert];
        }
        [__holder__ removeObjectAtIndex:0];
    }];
}

@end

