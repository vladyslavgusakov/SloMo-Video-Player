//
//  ViewController.h
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/13/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) id delegate;

@end

