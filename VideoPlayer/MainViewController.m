//
//  ViewController.m
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/13/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import "MainViewController.h"
#import "VideoViewController.h"
#import "MyCollectionViewCell.h"
#import "PlayerViewController.h"

@interface MainViewController () {
    VideoViewController *videoController;
    PlayerViewController *playerController;
    NSURL *videoUrl;
    BOOL inEditMode;
    NSString *documentsDir;
    NSArray *documentsDirContent;
}

- (IBAction)navigateToVideoVC:(id)sender;
- (IBAction)editMode:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *videosArray;
@property (strong, nonatomic) NSMutableArray *videoPictures;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.videosArray = [NSMutableArray new];
    self.videoPictures = [NSMutableArray new];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    
    videoController = (VideoViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"videoVC"];
    playerController = (PlayerViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"playerVC"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDir = [paths objectAtIndex:0];
    documentsDirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDir error:nil];
    
}
-(void) viewWillAppear:(BOOL)animated {
    
    inEditMode = NO;
    [self.editButtonItem setTitle:@"Edit"];
    [self updateCollectionView];
}

-(void) updateCollectionView {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDir = [paths objectAtIndex:0];
    documentsDirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDir error:nil];
    
    for (int count = 0; count < (int)[documentsDirContent count]; count++)
    {
        NSURL *fileURL = [NSURL fileURLWithPath:[documentsDir stringByAppendingPathComponent:[documentsDirContent objectAtIndex:count]]];
        NSLog(@"File %d: %@", (count + 1), fileURL);
        if (![self.videosArray containsObject:fileURL]) {
            [self.videosArray addObject:fileURL];
        }
    }
    
    [self.collectionView reloadData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.videosArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MyCollectionViewCell *myCell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:@"MyCell"
                                            forIndexPath:indexPath];
    

        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videosArray[indexPath.row]];
        AVPlayerLayer *playerLayer = ((AVPlayerLayer *) myCell.playerImageView.layer);
        AVPlayer *player = [AVPlayer playerWithPlayerItem: playerItem];
        myCell.playerImageView.player = player;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.videoPictures addObject:player];

    
    if (inEditMode == YES) {
        myCell.filmPic.image = [UIImage imageNamed:@"delete.png"];
    }
    else {
        myCell.filmPic.image = [UIImage imageNamed:@"film_2.png"];
    }

    return myCell;
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (inEditMode == YES) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[documentsDir stringByAppendingPathComponent:documentsDirContent[indexPath.row]] error:nil];
        if (success) {
            NSLog(@"OK");
            [self.videosArray removeObjectAtIndex:indexPath.row];
            [self.collectionView reloadData];
        }
        
    }
    else {
        playerController.url = [self.videosArray objectAtIndex:indexPath.row];
        [self presentViewController:playerController animated:YES completion:nil];
    }
    
}

- (IBAction)navigateToVideoVC:(id)sender {
    [self presentViewController:videoController animated:YES completion:nil];
}

- (IBAction)editMode:(UIBarButtonItem *)sender {
    inEditMode = !inEditMode;
    [self.collectionView reloadData];
    if (inEditMode == YES) {
        [sender setTitle:@"Done"];
    }
    else {
        [sender setTitle:@"Edit"];
    }
}
@end
