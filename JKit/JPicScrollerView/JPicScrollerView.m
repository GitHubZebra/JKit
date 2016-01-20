//
//  JPicScrollerView.m
//  JKitDemo
//
//  Created by elongtian on 16/1/19.
//  Copyright © 2016年 陈杰. All rights reserved.
//

#define myWidth self.frame.size.width
#define myHeight self.frame.size.height
#define pageSize (myHeight * 0.2 > 25 ? 25 : myHeight * 0.2)

#import "JPicScrollerView.h"
#import "JWebImageManager.h"
#import "JPageControl.h"

@interface JPicScrollerView () <UIScrollViewDelegate>

@property (nonatomic,strong) NSMutableDictionary *imageData;

@end

@implementation JPicScrollerView{
    
    __weak  UIImageView *_leftImageView,*_centerImageView,*_rightImageView;

    __weak  UILabel *_titleLabel;

    __weak  UIScrollView *_scrollView;

    __weak  JPageControl *_PageControl;

    NSTimer *_timer;

    NSInteger _currentIndex;

    NSInteger _MaxImageCount;

    BOOL _isNetwork;

    BOOL _hasTitle;
    
    UIImageView *_img;
    
    UIView *_titleView;
}


- (void)setMaxImageCount:(NSInteger)MaxImageCount {
    _MaxImageCount = MaxImageCount;
    
    [self prepareImageView];
    [self preparePageControl];
    
    [self setUpTimer];
    
    [self changeImageLeft:_MaxImageCount-1 center:0 right:1];
}


- (void)imageViewDidTap {
    if (self.imageViewDidTapAtIndex != nil) {
        self.imageViewDidTapAtIndex(_currentIndex);
    }
}

+ (instancetype)j_picScrollViewWithFrame:(CGRect)frame WithImageUrls:(NSArray<NSString *> *)imageUrl {
    return  [[JPicScrollerView alloc] initWithFrame:frame WithImageNames:imageUrl];
}
+ (instancetype)j_picScrollViewWithFrame:(CGRect)frame{
    return [[JPicScrollerView alloc]initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame WithImageNames:(NSArray<NSString *> *)ImageName {
    self = [super initWithFrame:frame];
    if (ImageName.count) {
        [self setImageUrlStrings:ImageName];
    }
    return self;
}

- (void)setImageUrlStrings:(NSArray *)imageUrlStrings{
    _imageUrlStrings = imageUrlStrings;
    if (_imageUrlStrings.count < 1) {
        return ;
    }
    if(_imageUrlStrings.count == 1 ) {
        
//        if (!_img) {
//            _img = [[UIImageView alloc] initWithFrame:self.bounds];
//            [self addSubview:_img];
//            _centerImageView = _img;
//        }
//        if (!_titleView) {
//            _titleView = [self creatLabelBgView];
//            _titleLabel = (UILabel *)_titleView.subviews.firstObject;
//            [self addSubview:_titleView];
//        }
//        _isNetwork = [_imageUrlStrings.firstObject hasPrefix:@"http://"];
//        
//        if (_isNetwork) {
//            JWebImageManager *manager = [JWebImageManager shareManager];
//            
//            [manager downloadImageWithUrlString:_imageUrlStrings.firstObject];
//            
//            [manager setDownLoadImageComplish:^(UIImage *image, NSString *url) {
//                _img.image = image;
//            }];
//            
//        }else {
//            _img.image = [UIImage imageNamed:_imageUrlStrings.firstObject];
//        }
    }
    
    _imageData = [NSMutableDictionary dictionaryWithCapacity:_imageUrlStrings.count];
    
    _isNetwork = [imageUrlStrings.firstObject hasPrefix:@"http://"];
    
    if (_isNetwork) {
        
        JWebImageManager *manager = [JWebImageManager shareManager];
        
        [manager setDownLoadImageComplish:^(UIImage *image, NSString *url) {
            [self.imageData setObject:image forKey:url];
            [self changeImageLeft:_currentIndex-1 center:_currentIndex right:_currentIndex+1];
        }];
        
        for (NSString *urlSting in imageUrlStrings) {
            [manager downloadImageWithUrlString:urlSting];
        }
        
    }else {
        
        for (NSString *name in imageUrlStrings) {
            [self.imageData setObject:[UIImage imageNamed:name] forKey:name];
        }
        
        
    }
    
    [self prepareScrollView];
    [self setMaxImageCount:self.imageUrlStrings.count];
}
- (void)prepareScrollView {
    
    UIScrollView *sc = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:sc];
    
    _scrollView = sc;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    
    _scrollView.contentSize = CGSizeMake(myWidth * 3,0);
    
    _AutoScrollDelay = 2.0f;
    _currentIndex = 0;
}

- (void)prepareImageView {
    
    UIImageView *left = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,myWidth, myHeight)];
    UIImageView *center = [[UIImageView alloc] initWithFrame:CGRectMake(myWidth, 0,myWidth, myHeight)];
    UIImageView *right = [[UIImageView alloc] initWithFrame:CGRectMake(myWidth * 2, 0,myWidth, myHeight)];
    
    center.userInteractionEnabled = YES;
    [center addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDidTap)]];
    
    [_scrollView addSubview:left];
    [_scrollView addSubview:center];
    [_scrollView addSubview:right];
    
    _leftImageView = left;
    _centerImageView = center;
    _rightImageView = right;
    
}

- (void)preparePageControl {
    
    JPageControl *page = [[JPageControl alloc] initWithFrame:CGRectMake(0,myHeight - pageSize,myWidth, 7)];
    
    
    page.pageIndicatorTintColor = [UIColor lightGrayColor];
    page.currentPageIndicatorTintColor =  [UIColor whiteColor];
    page.numberOfPages = _MaxImageCount;
    page.currentPage = 0;
    
    [self addSubview:page];
    
    
    _PageControl = page;
}

- (void)setStyle:(PageControlStyle)style {
    CGFloat w = _MaxImageCount * 17.5;
    _PageControl.frame = CGRectMake(0, 0, w, 7);
    
    if (style == PageControlAtRight || _hasTitle) {
        _PageControl.center = CGPointMake(myWidth-w*0.5, myHeight-pageSize * 0.5);
    }else if(style == PageControlAtCenter) {
        _PageControl.center = CGPointMake(myWidth * 0.5,myHeight-pageSize * 0.5);
    }
}

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
    _PageControl.pageIndicatorTintColor = pageIndicatorTintColor;
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
    _PageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor;
}

- (void)setImagePageStateNormal:(UIImage *)imagePageStateNormal{
    _PageControl.imagePageStateNormal = imagePageStateNormal;
}
- (void)setImagePageStateHighlighted:(UIImage *)imagePageStateHighlighted{
    _PageControl.imagePageStateHighlighted = imagePageStateHighlighted;
}



- (void)setTitleData:(NSArray<NSString *> *)titleData {
    if (titleData.count < 1)  return;
    
    if (titleData.count == 1) {
        _titleLabel.text = titleData.firstObject;
        return;
    }
    
    if (titleData.count < _imageData.count) {
        NSMutableArray *temp = [NSMutableArray arrayWithArray:titleData];
        for (int i = 0; i < _imageData.count - titleData.count; i++) {
            [temp addObject:@""];
        }
        _titleData = temp;
    }else {
        
        _titleData = titleData;
    }
    
    [self prepareTitleLabel];
    _hasTitle = YES;
    [self changeImageLeft:_MaxImageCount-1 center:0 right:1];
}


- (void)prepareTitleLabel {
    
    [self setStyle:PageControlAtRight];
    
    UIView *titleView = [self creatLabelBgView];
    
    _titleLabel = (UILabel *)titleView.subviews.firstObject;
    
    [self addSubview:titleView];
    
    [self bringSubviewToFront:_PageControl];
}



- (UIView *)creatLabelBgView {
    
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, myHeight-pageSize, myWidth, pageSize)];
    v.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8,0, myWidth-_PageControl.frame.size.width-16,pageSize)];
    label.textAlignment = NSTextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:pageSize*0.5];
    
    [v addSubview:label];
    
    return v;
}

- (void)setTextColor:(UIColor *)textColor {
    _titleLabel.textColor = textColor;
}

- (void)setFont:(UIFont *)font {
    _titleLabel.font = font;
}

#pragma mark scrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self setUpTimer];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self removeTimer];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self changeImageWithOffset:scrollView.contentOffset.x];
}


- (void)changeImageWithOffset:(CGFloat)offsetX {
    
    if (offsetX >= myWidth * 2) {
        _currentIndex++;
        
        if (_currentIndex == _MaxImageCount-1) {
            
            [self changeImageLeft:_currentIndex-1 center:_currentIndex right:0];
            
        }else if (_currentIndex == _MaxImageCount) {
            
            _currentIndex = 0;
            [self changeImageLeft:_MaxImageCount-1 center:0 right:1];
            
        }else {
            [self changeImageLeft:_currentIndex-1 center:_currentIndex right:_currentIndex+1];
        }
        _PageControl.currentPage = _currentIndex;
        
    }
    
    if (offsetX <= 0) {
        _currentIndex--;
        
        if (_currentIndex == 0) {
            
            [self changeImageLeft:_MaxImageCount-1 center:0 right:1];
            
        }else if (_currentIndex == -1) {
            
            _currentIndex = _MaxImageCount-1;
            [self changeImageLeft:_currentIndex-1 center:_currentIndex right:0];
            
        }else {
            [self changeImageLeft:_currentIndex-1 center:_currentIndex right:_currentIndex+1];
        }
        
        _PageControl.currentPage = _currentIndex;
    }
    
}

- (void)changeImageLeft:(NSInteger)LeftIndex center:(NSInteger)centerIndex right:(NSInteger)rightIndex {
    
    if (self.imageUrlStrings.count == 1) {
        _leftImageView.image = [self setImageWithIndex:0];
        _centerImageView.image = [self setImageWithIndex:0];
        _rightImageView.image = [self setImageWithIndex:0];
        
    }else{
        _leftImageView.image = [self setImageWithIndex:LeftIndex];
        _centerImageView.image = [self setImageWithIndex:centerIndex];
        _rightImageView.image = [self setImageWithIndex:rightIndex];
    }

    
    if (_hasTitle) {
        _titleLabel.text = [self.titleData objectAtIndex:centerIndex];
    }
    
    [_scrollView setContentOffset:CGPointMake(myWidth, 0)];
}

-(void)setPlaceImage:(UIImage *)placeImage {
    if (!_isNetwork) return;
    
    _placeImage = placeImage;
    if (_MaxImageCount < 2 && _centerImageView) {
        _centerImageView.image = _placeImage;
    }else {
        [self changeImageLeft:_MaxImageCount-1 center:0 right:1];
    }
}

- (UIImage *)setImageWithIndex:(NSInteger)index {
    if (index < 0||index >= self.imageUrlStrings.count) {
        return _placeImage;
    }
    //从内存缓存中取,如果没有使用占位图片
    UIImage *image = [self.imageData objectForKey:self.imageUrlStrings[index]];
    
    return image ? image : _placeImage;
}


- (void)scorll {
    [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x + myWidth, 0) animated:YES];
}

- (void)setAutoScrollDelay:(NSTimeInterval)AutoScrollDelay {
    _AutoScrollDelay = AutoScrollDelay;
    [self removeTimer];
    [self setUpTimer];
}

- (void)setUpTimer {
    if (_AutoScrollDelay < 0.5||_timer != nil || _imageUrlStrings.count == 1) return;
    
    _timer = [NSTimer timerWithTimeInterval:_AutoScrollDelay target:self selector:@selector(scorll) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    if (_timer == nil) return;
    [_timer invalidate];
    _timer = nil;
}

-(void)dealloc {
    [self removeTimer];
}

//
//- (void)getImage {
//
//    SDWebImageManager *manager = [SDWebImageManager sharedManager];
//
//    for (NSString *urlString in _imageData) {
//
//        [manager downloadImageWithURL:[NSURL URLWithString:urlString] options:SDWebImageHighPriority progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
//            if (error) {
//                NSLog(@"%@",error);
//            }
//        }];
//    }
//
//}
//- (UIImage *)setImageWithIndex:(NSInteger)index {
//
//  UIImage *image =
//    [[[SDWebImageManager sharedManager] imageCache] imageFromMemoryCacheForKey:_imageData[index]];
//    if (image) {
//        return image;
//    }else {
//        return _placeImage;
//    }
//
//}







@end
