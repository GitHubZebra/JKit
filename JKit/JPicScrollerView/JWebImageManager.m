//
//  JWebImageManager.m
//  JKitDemo
//
//  Created by elongtian on 16/1/19.
//  Copyright © 2016年 陈杰. All rights reserved.
//

#import "JWebImageManager.h"

@interface JWebImageManager ()

@property (nonatomic,copy) NSString *cachePath;

@property (nonatomic,strong) NSMutableDictionary *DownloadImageCount;

@end

@implementation JWebImageManager
+ (instancetype)shareManager {
    
    static JWebImageManager *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JWebImageManager alloc] init];
    });
    return  instance;
}

#pragma mark downLoadImage

- (BOOL)LoadDiskCacheWithUrlString:(NSString *)urlString {
    //取沙盒缓存
    NSData *data = [NSData dataWithContentsOfFile:[self.cachePath stringByAppendingPathComponent:urlString.lastPathComponent]];
    
    if (data.length > 0 ) {
        
        UIImage *image = [UIImage imageWithData:data];
        
        if (image) {
            if (self.downLoadImageComplish) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.downLoadImageComplish(image,urlString);
                });
            }
            return YES;
        }else {
            [[NSFileManager defaultManager] removeItemAtPath:[self.cachePath stringByAppendingPathComponent:urlString.lastPathComponent] error:NULL];
        }
    }
    return NO;
}


- (void)downloadImageWithUrlString:(NSString *)urlSting {
    
    if ([self LoadDiskCacheWithUrlString:urlSting]) {
        return;
    }
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
        
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlSting] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            [self downLoadImagefinish:data
                                  url:urlSting
                                error:error
                             response:response];
            
        }] resume];
        
    }else {
        [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlSting]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [self downLoadImagefinish:data
                                      url:urlSting
                                    error:error
                                 response:response];
        }];
        
    }
}



- (void)downLoadImagefinish:(NSData *)data url:(NSString *)urlString error:(NSError *)error response:(NSURLResponse *)response{
    
    if (error) {
        [self repeatDownLoadImage:urlString error:error];
        return ;
    }
    
    UIImage *image = [UIImage imageWithData:data];
    
    
    if (!image) {
        
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        NSString *errorData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"错误数据字符串信息:%@\nhttp statusCode(错误代码):%zd",errorData,res.statusCode] code:0 userInfo:nil];
        
        [self repeatDownLoadImage:urlString error:error];
        return ;
    }
    
    //                沙盒缓存
    [data writeToFile:[self.cachePath stringByAppendingPathComponent:urlString.lastPathComponent] atomically:YES];
    
    if (self.downLoadImageComplish) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downLoadImageComplish(image,urlString);
        });
    }
}

- (void)repeatDownLoadImage:(NSString *)urlString error:(NSError *)error{
    
    NSNumber *num = [self.DownloadImageCount objectForKey:urlString];
    NSInteger count = num ? [num integerValue] : 0;
    
    if (self.DownloadImageRepeatCount > count ) {
        
        [self.DownloadImageCount setObject:@(++count) forKey:urlString];
        [self downloadImageWithUrlString:urlString];
        
    }else {
        
        if (self.downLoadImageError) {
            self.downLoadImageError(error,urlString);
        }
    }
}



#pragma mark lazyload


- (NSMutableDictionary *)DownloadImageCount {
    if (!_DownloadImageCount) {
        _DownloadImageCount = [NSMutableDictionary dictionary];
    }
    return _DownloadImageCount;
}

- (NSString *)cachePath {
    if (!_cachePath) {
        
        _cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:NSStringFromClass([self class])];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:_cachePath withIntermediateDirectories:NO attributes:nil error:NULL];
        
    }
    return _cachePath;
}

@end
