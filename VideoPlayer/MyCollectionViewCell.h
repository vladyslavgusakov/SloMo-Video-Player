//
//  MyCollectionViewCell.h
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/13/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerView.h"

@interface MyCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *filmPic;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet PlayerView *playerImageView;

@end
