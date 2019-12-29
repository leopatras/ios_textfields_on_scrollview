/* the sample demonstrates how to wire UITextFields to get the wanted
   "scroll into view" behavior on a UIScrollView when tapping/focusing fields
   The UITextField scrolls into view upon  [MyTextField becomeFirstResponder]
 */
#import <UIKit/UIKit.h>
@interface UIView(AutoLayoutHelpers)
@end
@implementation UIView(AutoLayoutHelpers)
-(void)addAutoLayoutSubview:(UIView *)subview
{
  [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self addSubview:subview];
}
-(void)pinLeadingToSuperview:(CGFloat)innerMargin
{
  [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor constant:innerMargin].active = YES;
}
-(void)pinTrailingToSuperview:(CGFloat)innerMargin
{
  [self.superview.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:innerMargin].active = YES;
}
-(void)pinTopToSuperview:(CGFloat)innerMargin
{
  [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:innerMargin].active = YES;
}
-(void)pinBottomToSuperview:(CGFloat)innerMargin
{
  [self.superview.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:innerMargin].active = YES;
}
-(void)pinBottomToTopOf:(UIView*)view constant:(CGFloat)constant
{
  [view.topAnchor constraintEqualToAnchor:self.bottomAnchor constant:constant].active = YES;
}
-(void)pinToSuperView:(CGFloat)margin
{
  [self pinTopToSuperview:margin];
  [self pinBottomToSuperview:margin];
  [self pinLeadingToSuperview:margin];
  [self pinTrailingToSuperview:margin];
}
@end
@class MyAppDelegate;
@interface MyTextField:UITextField
@property (weak,nonatomic) MyAppDelegate* appDelegate;
@end
@interface MyAppDelegate : UIResponder <UIApplicationDelegate,UITextFieldDelegate>
{
  UIWindow* _win;
  UIScrollView* _scroller;
  NSMutableArray<MyTextField*>* _textFields;
  MyTextField* __weak _current;
}
@end
@interface MyScrollView:UIScrollView
@end
@implementation MyScrollView
//for debugging the automatic into view scrolling, put a breakpoint here
-(void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
  [super scrollRectToVisible:rect animated:animated];
}
@end
@implementation MyAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self observeKeyboard];
  _textFields=[NSMutableArray array];
  _win=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  UIViewController* c=[[UIViewController alloc] init];
  [self setupContent:c.view];
  _win.rootViewController=[[UINavigationController alloc] initWithRootViewController:c];
  c.navigationItem.title=@"UITextFields on UIScrollView";
  [_win makeKeyAndVisible];
  return YES;
}

- (UITextField*)newTextField:(UIView*)contentView
{
  MyTextField* t=[[MyTextField alloc] init];
  t.delegate=self;
  t.borderStyle = UITextBorderStyleRoundedRect;
  t.clearButtonMode = UITextFieldViewModeWhileEditing;
  t.inputAccessoryView=[self createInputAccessoryView];
  [contentView addAutoLayoutSubview:t];
  [t pinLeadingToSuperview:10];
  [t pinTrailingToSuperview:10];
  [_textFields addObject:t];
  t.text=[NSString stringWithFormat:@"TextField%ld",(long)_textFields.count];
  t.appDelegate=self;
  return t;
}

-(void)observeKeyboard
{
  NSNotificationCenter* c=[NSNotificationCenter defaultCenter];
  [c addObserver:self
        selector:@selector(keyboardShown:)
            name:UIKeyboardDidShowNotification object:nil];
  [c addObserver:self
        selector:@selector(keyboardShown:)
            name:UIKeyboardWillChangeFrameNotification object:nil];
  [c addObserver:self
        selector:@selector(keyboardHidden:)
            name:UIKeyboardWillHideNotification object:nil];
}
- (void) keyboardShown:(NSNotification *)notification
{
  CGRect rect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  UIEdgeInsets ci=_scroller.contentInset;
  ci.bottom=rect.size.height;
  _scroller.contentInset = ci;
  _scroller.scrollIndicatorInsets = ci;
}
- (void) keyboardHidden:(NSNotification *)notification
{
  UIEdgeInsets ci=_scroller.contentInset;
  ci.bottom=0;
  _scroller.contentInset = ci;
  _scroller.scrollIndicatorInsets = ci;
}
-(void)setupContent:(UIView*)v
{
  v.backgroundColor=UIColor.whiteColor;
  v.accessibilityIdentifier=@"Base";
  MyScrollView* sc=[[MyScrollView alloc] init];
  _scroller=sc;
  sc.accessibilityIdentifier=@"MyScrollView";
  sc.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
  [v addAutoLayoutSubview:sc];
  [sc pinToSuperView:0];
  UIView* contentView=[[UIView alloc] init];
  contentView.accessibilityIdentifier=@"ContentView";
  [sc addAutoLayoutSubview:contentView];
  [contentView pinTopToSuperview:0];
  [contentView pinBottomToSuperview:0];
  //ensures that the contentSize of the scrollview is not ambigous
  UILayoutGuide* fr=sc.frameLayoutGuide;
  UILayoutGuide* ct=sc.contentLayoutGuide;
  [ct.widthAnchor constraintEqualToAnchor:fr.widthAnchor].active=TRUE;
  //ensure vertical stretch to the safe areas (iPhone X landscape)
  NSLayoutAnchor* ctLeading=contentView.leadingAnchor;
  NSLayoutAnchor* ctTrailing=contentView.trailingAnchor;
  UILayoutGuide * lg = v.safeAreaLayoutGuide;
  [ctLeading constraintEqualToAnchor:lg.leadingAnchor].active = YES;
  [ctTrailing constraintEqualToAnchor:lg.trailingAnchor].active = YES;
  UITextField* first=[self newTextField:contentView]; //text field on top
  [first pinTopToSuperview:10];
  UITextField* prev=first;
  //add 10 fields in the middle
  for (NSInteger idx=0;idx<10;idx++) {
    UITextField* t=[self newTextField:contentView];
    [prev pinBottomToTopOf:t constant:50];
    prev=t;
  }
  UITextField* last=[self newTextField:contentView]; //textfield on bottom
  [prev pinBottomToTopOf:last constant:50];
  [last pinBottomToSuperview:10];
}

static UIBarButtonItem *s_kb_up = nil;
static UIBarButtonItem *s_kb_down = nil;
-(UIView*)createInputAccessoryView
{
  static UIToolbar* s_kb_toolbar = nil;
  static UIBarButtonItem *s_kb_hide = nil;
  if (s_kb_toolbar!=nil) { //share this view
    return s_kb_toolbar;
  }
  UIToolbar *toolbar = [[UIToolbar alloc] init];
  [toolbar setBarStyle:UIBarStyleDefault];
  toolbar.accessibilityIdentifier=@"KEYBOARD_TOOLBAR";
  s_kb_up =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:103 target:self action:@selector(sendPrev:)];
  s_kb_up.accessibilityIdentifier=@"KEYBOARD_ACCESSORY_UP";
  s_kb_down =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:104 target:self action:@selector(sendNext:)];
  s_kb_down.accessibilityIdentifier=@"KEYBOARD_ACCESSORY_DOWN";
  UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
  s_kb_hide =
  [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
  s_kb_hide.accessibilityIdentifier=@"KEYBOARD_ACCESSORY_HIDE";
  [toolbar setItems:@[s_kb_up,s_kb_down,spacer,s_kb_hide]];
  [toolbar sizeToFit]; //causes auto layout warnings
  s_kb_toolbar=toolbar;
  return toolbar;
}
-(void)updatePrevNext:(MyTextField*)current
{
  _current=current;
  if (_textFields.count==0) { return;}
  s_kb_up.enabled=(current!=_textFields[0]);
  s_kb_down.enabled=(current!=_textFields[_textFields.count-1]);
}
-(void)resignCurrent
{
  _current=nil;
}
-(void)focusTextField:(NSInteger)step
{
  MyTextField* tf=_current;
  NSInteger idx=[_textFields indexOfObject:tf];
  if (idx==NSNotFound) { //sanity
    return;
  }
  idx+=step;
  if (idx<0||idx>=_textFields.count) {
    return;
  }
  MyTextField* prevOrNext=_textFields[idx];
  [prevOrNext becomeFirstResponder];
}
-(void)sendPrev:(id)sender
{
  s_kb_up.enabled=false;
  [self focusTextField:-1];
}
-(void)sendNext:(id)sender
{
  s_kb_down.enabled=false;
  [self focusTextField:+1];
}
-(void)hideKeyboard
{
  [_current resignFirstResponder];
}
@end

@implementation MyTextField //subclass to manage prev/next inputAccessoryView buttons
-(BOOL)becomeFirstResponder
{
  //calls private [UITextField scrollTextFieldToVisibleIfNecessary]
  //which in turn calls [MyScrollView scrollRectToVisible:animated:]
  BOOL result=[super becomeFirstResponder];
  if (result){
    [self.appDelegate updatePrevNext:self];
  }
  return result;
}
-(BOOL)resignFirstResponder
{
  BOOL result=[super resignFirstResponder];
  if (result) {
    [self.appDelegate resignCurrent];
  }
  return result;
}
@end
int main(int argc, char * argv[]) {
  @autoreleasepool {
      return UIApplicationMain(argc, argv, nil, NSStringFromClass([MyAppDelegate class]));
  }
}
