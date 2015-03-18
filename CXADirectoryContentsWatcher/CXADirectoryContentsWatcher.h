//
//  CXADirectoryContentsWatcher.h
//  CXADirectoryContentsWatcher
//
//  Created by CHEN Xian’an on 3/19/15.
//  Copyright (c) 2015 lazyapps. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for CXADirectoryContentsWatcher.
FOUNDATION_EXPORT double CXADirectoryContentsWatcherVersionNumber;

//! Project version string for CXADirectoryContentsWatcher.
FOUNDATION_EXPORT const unsigned char CXADirectoryContentsWatcherVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CXADirectoryContentsWatcher/PublicHeader.h>

#import <Foundation/Foundation.h>

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#endif

#ifndef NS_ASSUME_NONNULL_END
#define NS_ASSUME_NONNULL_END
#endif

NS_ASSUME_NONNULL_BEGIN

@class CXADirectoryContentsWatcher;
@protocol CXADirectoryContentsWatcherDelegate <NSObject>

- (void)directoryWatcher:(CXADirectoryContentsWatcher * )dirWatcher didFinishCopyItemAtURL:(NSURL *)fileURL isReplacement:(BOOL)isReplacement;
- (void)directoryWatcher:(CXADirectoryContentsWatcher *)dirWatcher didRemoveItemAtURL:(NSURL *)fileURL;

@end

@interface CXADirectoryContentsWatcher : NSObject

@property (nonatomic, weak) id <CXADirectoryContentsWatcherDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *directoryURL;

- (instancetype)initWithDirectoryURL:(NSURL *)dirURL delegate:(id <CXADirectoryContentsWatcherDelegate>)delegate;
- (BOOL)start;
- (void)stop;

NS_ASSUME_NONNULL_END

@end
