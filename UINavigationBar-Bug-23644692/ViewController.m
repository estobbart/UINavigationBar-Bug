//
//  ViewController.m
//  UINavigationBar-Bug-23644692
//
//  Created by Eric Stobbart on 12/4/15.
//  Copyright © 2015 Eric Stobbart. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
  UINavigationBar *ejs_navigationBar;
  NSInteger ejs_count;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  ejs_navigationBar = [[UINavigationBar alloc] init];
  ejs_navigationBar.delegate = self;
  [self.view addSubview:ejs_navigationBar];
  [self performSelectorInBackground:@selector(test)
                         withObject:nil];
}

- (void)test {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self ejs_setItems];
  });
  sleep(1);
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self ejs_pushItem];
  });
  sleep(1);
  
  // During the shouldPopItem phase the counts are correct.
  // During the didPopItem phase the counts are incorrect.
  dispatch_async(dispatch_get_main_queue(), ^{
    [self ejs_popItem];
  });
  sleep(1);

  dispatch_async(dispatch_get_main_queue(), ^{
    [self ejs_popItem];
  });
}

- (void)ejs_setItems {
  ejs_count = 1;
  [ejs_navigationBar setItems:@[[[UINavigationItem alloc] init]]
                     animated:YES];
}

- (void)ejs_pushItem {
  [ejs_navigationBar pushNavigationItem:[[UINavigationItem alloc] init]
                               animated:YES];
}

- (void)ejs_popItem {
  [ejs_navigationBar popNavigationItemAnimated:YES];
}

- (void)ejs_logNavigationItems:(SEL)method
                      expected:(NSInteger)expected
                        actual:(NSInteger)actual {
  NSLog(@"%@ expected:%lu actual:%lu", NSStringFromSelector(method), expected, actual);
}

// called to push. return NO not to.
- (BOOL)navigationBar:(UINavigationBar *)navigationBar
       shouldPushItem:(UINavigationItem *)item {
  [self ejs_logNavigationItems:_cmd
                      expected:ejs_count
                        actual:navigationBar.items.count];
  return YES;
}


// called at end of animation of push or immediately if not animated
- (void)navigationBar:(UINavigationBar *)navigationBar
          didPushItem:(UINavigationItem *)item {
  ejs_count += 1;
  [self ejs_logNavigationItems:_cmd
                      expected:ejs_count
                        actual:navigationBar.items.count];
}

// same as push methods
- (BOOL)navigationBar:(UINavigationBar *)navigationBar
        shouldPopItem:(UINavigationItem *)item {
  NSLog(@"%@ items:%@", NSStringFromSelector(_cmd), navigationBar.items);
  NSLog(@"%@ topItem:%@", NSStringFromSelector(_cmd), navigationBar.topItem);
  [self ejs_logNavigationItems:_cmd
                      expected:ejs_count
                        actual:navigationBar.items.count];
  return YES;
} 

- (void)navigationBar:(UINavigationBar *)navigationBar
           didPopItem:(UINavigationItem *)item {
  NSLog(@"%@ items:%@", NSStringFromSelector(_cmd), navigationBar.items);
  NSLog(@"%@ topItem:%@", NSStringFromSelector(_cmd), navigationBar.topItem);
  ejs_count -= 1;
  [self ejs_logNavigationItems:_cmd
                      expected:ejs_count
                        actual:navigationBar.items.count];
  if (navigationBar.items.count != ejs_count) {
    NSException *e = [[NSException alloc] initWithName:@"UINavigationBar Bug"
                                                reason:@"incorrect number of items and nil topItem"
                                              userInfo:@{}];
    @throw e;
  }
}

@end
