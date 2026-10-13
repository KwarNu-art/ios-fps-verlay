#import <UIKit/UIKit.h>  
#import <QuartzCore/QuartzCore.h>  
  
static UIColor *FPSGreen(CGFloat a) {  
    return [UIColor colorWithRed:0.20 green:1.00 blue:0.40 alpha:a];  
}  
  
@interface FPSLabelView : UIView  
@property (nonatomic, strong) CADisplayLink *link;  
@property (nonatomic, strong) UILabel *label;  
@property (nonatomic, assign) CFTimeInterval lastTime;  
@property (nonatomic, assign) NSUInteger frames;  
@end  
  
@implementation FPSLabelView  
  
- (instancetype)initWithFrame:(CGRect)frame {  
    self = [super initWithFrame:frame];  
    if (!self) return nil;  
  
    self.userInteractionEnabled = NO;  
    self.layer.cornerRadius = frame.size.height / 2.0;  
    self.layer.masksToBounds = YES;  
    self.layer.borderWidth = 0.5;  
    self.layer.borderColor = FPSGreen(0.55).CGColor;  
    self.backgroundColor = FPSGreen(0.10);  
  
    // Frosted glass background layer  
    UIVisualEffectView *glass = [[UIVisualEffectView alloc]  
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];  
    glass.frame = self.bounds;  
    glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;  
    [self addSubview:glass];  
  
    // FPS display label  
    _label = [[UILabel alloc] initWithFrame:self.bounds];  
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;  
    _label.textAlignment = NSTextAlignmentCenter;  
    _label.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightSemibold];  
    _label.textColor = FPSGreen(1.0);  
    _label.text = @"-- FPS";  
    [self addSubview:_label];  
  
    return self;  
}  
  
- (void)startMeasuring {  
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];  
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];  
}  
  
- (void)stopMeasuring {  
    [_link invalidate];  
    _link = nil;  
}  
  
- (void)tick:(CADisplayLink *)link {  
    if (self.lastTime == 0) {  
        self.lastTime = link.timestamp;  
        return;  
    }  
    self.frames++;  
    CFTimeInterval delta = link.timestamp - self.lastTime;  
    if (delta >= 1.0) {  
        self.label.text = [NSString stringWithFormat:@"%.0f FPS", self.frames / delta];  
        self.frames = 0;  
        self.lastTime = link.timestamp;  
    }  
}  
  
@end  
  
// MARK: - Installer & Life-Cycle Bootstrap  
  
static UIWindow *gFPSWindow = nil;  
static FPSLabelView *gFPSView = nil;  
  
static void FPSOverlayInstall(void) {  
    if (gFPSWindow) return;  
  
    CGRect screen = UIScreen.mainScreen.bounds;  
    CGRect frame = CGRectMake(screen.size.width - 72, 30, 62, 20);  
  
    UIWindow *window = nil;  
    if (@available(iOS 13.0, *)) {  
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {  
            if ([scene isKindOfClass:[UIWindowScene class]]) {  
                window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];  
                break;  
            }  
        }  
    }  
    if (!window) window = [[UIWindow alloc] initWithFrame:screen];  
  
    window.frame = screen;  
    window.windowLevel = UIWindowLevelStatusBar + 1;  
    window.backgroundColor = UIColor.clearColor;  
    window.userInteractionEnabled = NO;  
    window.rootViewController = [UIViewController new];  
    window.rootViewController.view.backgroundColor = UIColor.clearColor;  
    window.rootViewController.view.userInteractionEnabled = NO;  
  
    FPSLabelView *view = [[FPSLabelView alloc] initWithFrame:frame];  
    [window.rootViewController.view addSubview:view];  
    window.hidden = NO;  
  
    gFPSWindow = window;  
    gFPSView = view;  
    [view startMeasuring];  
}  
  
// Automatically initializes when the target app becomes active  
__attribute__((constructor))  
static void FPSOverlayBootstrap(void) {  
    [[NSNotificationCenter defaultCenter]  
        addObserverForName:UIApplicationDidBecomeActiveNotification  
                    object:nil  
                     queue:[NSOperationQueue mainQueue]  
                usingBlock:^(NSNotification *note) {  
        FPSOverlayInstall();  
    }];  
}
