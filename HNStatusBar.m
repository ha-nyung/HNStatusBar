//
//  HNStatusBar.m
//  HNStatusBar
//
// This is under The MIT License
//
// Copyright © 2012 Ha-Nyung Chung <minorblend@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>

#import "HNStatusBar.h"

#define TRANSITION_DURATION 0.35f
#define DISAPPEAR_AFTER 1.75f
#define PROGRESS_BAR_HEIGHT 3

static HNStatusBar *sharedInstance;

@interface HNStatusBar ()

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) UIColor *progressBarColorFrom;
@property (nonatomic, strong) UIColor *progressBarColorTo;
@property (nonatomic, strong) UIColor *backgroundColor;

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) CAGradientLayer *progressBar;

+ (HNStatusBar *)sharedInstance;

- (void)setText:(NSString *)text during:(NSTimeInterval)duration animated:(BOOL)animated;
- (void)clear;

@end

@implementation HNStatusBar {
    BOOL _originalStatusBarHidden;
}

+ (HNStatusBar *)sharedInstance
{
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[HNStatusBar alloc] init];
        });
    }

    return sharedInstance;
}

+ (void)setBackgroundColor:(UIColor *)color
{
    [[self sharedInstance] setBackgroundColor:color];
}

+ (void)setTextFont:(UIFont *)font
{
    [[self sharedInstance] setTextFont:font];
}

+ (void)setTextColor:(UIColor *)color
{
    [[self sharedInstance] setTextColor:color];
}

+ (void)setProgressBarGradientColorFrom:(id)fromColor to:(UIColor *)toColor
{
    [[self sharedInstance] setProgressBarColorFrom:fromColor];
    [[self sharedInstance] setProgressBarColorTo:toColor];
}

+ (void)setText:(NSString *)text
{
    [[self sharedInstance] setText:text during:DISAPPEAR_AFTER animated:YES];
}

+ (void)setText:(NSString *)text during:(NSTimeInterval)duration
{
    [[self sharedInstance] setText:text during:duration animated:YES];
}

+ (void)setText:(NSString *)text during:(NSTimeInterval)duration animated:(BOOL)animated
{
    [[self sharedInstance] setText:text during:duration animated:animated];
}

+ (void)clear
{
    [[self sharedInstance] clear];
}

+ (void)setProgress:(float)progress
{
    [[self sharedInstance] setProgress:progress];
}

- (id)init
{
    self = [super init];
    if (self) {
        UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
        if (!mainWindow)
            return nil;

        // default appearance
        self.textColor = [UIColor whiteColor];
        self.textFont = [UIFont boldSystemFontOfSize:12];
        self.progressBarColorFrom = [UIColor blueColor];
        self.progressBarColorTo = [UIColor redColor];

        self.frame = [UIScreen mainScreen].bounds;
        self.windowLevel = UIWindowLevelStatusBar + 1;
        self.userInteractionEnabled = NO;
        self.autoresizesSubviews = YES;
        self.backgroundColor = [UIColor blackColor];

        self.baseView = [[UIView alloc] init];
        self.baseView.clipsToBounds = YES;
        CGRect frame = [UIApplication sharedApplication].statusBarFrame;
        frame.size.height = 20;
        self.baseView.frame = frame;
        self.baseView.backgroundColor = [UIColor blackColor];

        [self addSubview:self.baseView];
        self.hidden = YES;
        _originalStatusBarHidden = self.hidden;

        [[UIApplication sharedApplication] addObserver:self
                                            forKeyPath:@"statusBarHidden"
                                               options:NSKeyValueObservingOptionNew
                                               context:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:@"statusBarHidden"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.progressBar)
        self.progressBar.frame = CGRectMake(0, 0,
                                            CGRectGetWidth(self.baseView.frame) * self.progress, PROGRESS_BAR_HEIGHT);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    if (![keyPath isEqualToString:@"statusBarHidden"])
        return;

    if ([UIApplication sharedApplication].statusBarHidden) {
        self.hidden = YES;
        _originalStatusBarHidden = YES;
    } else {
        self.hidden = _originalStatusBarHidden;
    }
}

- (void)setText:(NSString *)text during:(NSTimeInterval)duration animated:(BOOL)animated
{
    self.hidden = [UIApplication sharedApplication].statusBarHidden;
    _originalStatusBarHidden = self.hidden;

    UILabel *oldTextLabel = self.textLabel;

    UILabel *textLabel = [[UILabel alloc] initWithFrame:self.baseView.bounds];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.font = self.textFont;
    textLabel.textColor = self.textColor;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 1;
    textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    textLabel.text = text;

    if (animated) {
        CGRect originalFrame = textLabel.frame;
        CGRect frame = textLabel.frame;
        frame.origin.y -= CGRectGetHeight(frame);
        textLabel.frame = frame;
        [self.baseView addSubview:textLabel];
        [UIView animateWithDuration:TRANSITION_DURATION animations:^{
            textLabel.frame = originalFrame;
            oldTextLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [oldTextLabel removeFromSuperview];
        }];
    } else {
        [self.baseView addSubview:textLabel];
        [oldTextLabel removeFromSuperview];
    }

    self.textLabel = textLabel;

    if (duration > 0) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (textLabel.superview) { // run animation only if textLabel still exists
                if (animated) {
                    CGRect frame = textLabel.frame;
                    frame.origin.y += CGRectGetHeight(frame);
                    [UIView animateWithDuration:TRANSITION_DURATION animations:^{
                        textLabel.frame = frame;
                        textLabel.alpha = 0;
                        self.hidden = YES;
                        _originalStatusBarHidden = self.hidden;
                    } completion:^(BOOL finished) {
                        [textLabel removeFromSuperview];
                        if (([self.textLabel isEqual:textLabel] || !self.textLabel) && !self.progressBar) {
                            self.textLabel = nil;
                            self.progressBar = nil;
                        }
                    }];
                } else {
                    self.hidden = YES;
                    _originalStatusBarHidden = self.hidden;
                    [textLabel removeFromSuperview];
                    if (([self.textLabel isEqual:textLabel] || !self.textLabel) && !self.progressBar) {
                        self.textLabel = nil;
                        self.progressBar = nil;
                    }
                }
            }
        });
    }
}

- (void)clear
{
    self.hidden = YES;
    _originalStatusBarHidden = self.hidden;
    [self.textLabel removeFromSuperview];
    self.progress = 0;
}

- (void)setProgress:(float)progress
{
    if (progress == 0) {
        [self.progressBar removeFromSuperlayer];
        self.progressBar = nil;
        if (!self.textLabel) {
            self.hidden = YES;
            _originalStatusBarHidden = self.hidden;
        }
    } else {
        self.hidden = [UIApplication sharedApplication].statusBarHidden;
        _originalStatusBarHidden = self.hidden;

        if (!self.progressBar) { // lazy initialization
            self.progressBar = [[CAGradientLayer alloc] init];
            self.progressBar.startPoint = CGPointMake(0, 0.5);
            self.progressBar.endPoint = CGPointMake(1, 0.5);
            self.progressBar.cornerRadius = 1.5f;
            self.progressBar.masksToBounds = YES;
            self.progressBar.colors = @[ (id)self.progressBarColorFrom.CGColor, (id)self.progressBarColorTo.CGColor ];
            [self.baseView.layer addSublayer:self.progressBar];
        }

        self.progressBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.baseView.frame) * progress, PROGRESS_BAR_HEIGHT);
    }

    _progress = progress;
}

@end
