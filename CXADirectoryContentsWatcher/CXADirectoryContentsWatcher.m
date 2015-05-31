//
//  CXADirectoryContentsWatcher.m
//  CXADirectoryContentsWatcher
//
//  Copyright (c) 2013 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//
//  CXADirectoryContentsWatcher is released under the MIT license. In short, it's royalty-free but you must you keep the copyright notice in your code or software distribution.

#import "CXADirectoryContentsWatcher.h"

static char _kDirSourceToken, _kFileSourceToken;
static void _sourceFunc(void *);

typedef struct {
  char *token;
  BOOL isReplacement;
  __unsafe_unretained CXADirectoryContentsWatcher *watcher;
  __unsafe_unretained NSURL *fileURL;
} _SourceContext;

@interface _CXACopyingFileInfo : NSObject

@property (nonatomic, weak) CXADirectoryContentsWatcher *watcher;
@property (nonatomic, strong) NSURL *fileURL;
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_source_t source;
#else
@property (nonatomic, assign) dispatch_source_t source;
#endif
@property (nonatomic) NSUInteger lastFileSize;
@property (nonatomic) NSInteger possibleZeroSizeFileCheckCounter;

- (void)checkFinsihCopy;
- (void)poll;
- (void)stopPoll;
- (NSUInteger)fileSize;

@end

@interface CXADirectoryContentsWatcher(){
  dispatch_queue_t _watcherQueue;
  dispatch_source_t _dirSource;
  NSMutableSet *_lastFileURLs;
  NSMutableDictionary *_copyingFileInfos;
  NSMutableSet *_scheduledFiles;
}

- (NSMutableSet *)fileURLs;
- (void)handleDirContentsChange;
- (void)monitorCopyingFile:(NSURL *)fileURL isReplacement:(BOOL)isReplacement;
- (void)finishCopyingFile:(NSURL *)fileURL;
- (void)delayHandleFile:(NSURL *)fileURL;
- (void)confirmDeleteFile:(id)fileURL;

@end

@implementation CXADirectoryContentsWatcher

- (instancetype)initWithDirectoryURL:(NSURL *)dirURL
                            delegate:(id<CXADirectoryContentsWatcherDelegate>)delegate
{
  if (self = [super init]){
    _directoryURL = dirURL;
    _delegate = delegate;
    _lastFileURLs = [self fileURLs];
    // Abuse main queue to ensure we have a run loop for `-performSelector:withObject:afterDelay:`
    _watcherQueue = dispatch_get_main_queue();
  }

  return self;
}

- (void)dealloc
{
  [self stop];
}

- (BOOL)start
{
  if (_dirSource)
    [self stop];
  
  int fd = open([[self.directoryURL path] fileSystemRepresentation], O_EVTONLY);
  if (fd == -1)
    return NO;
  
  _dirSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, _watcherQueue);
  if (!_dirSource){
    close(fd);
    return NO;
  }
  
  _SourceContext *ctx = malloc(sizeof(_SourceContext));
  ctx->token = &_kDirSourceToken;
  ctx->watcher = self,
  ctx->fileURL = self.directoryURL;
  dispatch_set_context(_dirSource, ctx);
  dispatch_source_set_event_handler_f(_dirSource, _sourceFunc);
  __weak __typeof(&*self) weakSelf = self;
  dispatch_source_set_cancel_handler(_dirSource, ^{
    __strong __typeof(&*self) s = weakSelf;
    if (s){
      for (NSURL *URL in s->_scheduledFiles)
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(confirmDeleteFile:) object:URL];
      
      [s->_scheduledFiles removeAllObjects];
      [s->_copyingFileInfos enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        dispatch_source_cancel([obj source]);
      }];
      [s->_copyingFileInfos removeAllObjects];
    }
    
    free(ctx);
    close(fd);
  });
  
  dispatch_resume(_dirSource);
  
  return YES;
}

- (void)stop
{
  if (_dirSource){
    dispatch_source_cancel(_dirSource);
    _dirSource = nil;
  }
}

#pragma mark - private
- (NSMutableSet *)fileURLs
{
  return [NSMutableSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtURL:_directoryURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL]];
}

- (void)handleDirContentsChange
{
  NSMutableSet *curFiles = [self fileURLs];
  NSMutableSet *addedFiles = [curFiles mutableCopy];
  [addedFiles minusSet:_lastFileURLs]; 
  for (NSURL *URL in addedFiles){
    BOOL isReplacement = [_scheduledFiles containsObject:URL];
    [self monitorCopyingFile:URL isReplacement:isReplacement];
    if (isReplacement){
      [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(confirmDeleteFile:) object:URL];
      [_scheduledFiles removeObject:URL];
    }
  }
  
  NSMutableSet *removedFiles = _lastFileURLs;
  [removedFiles minusSet:curFiles];
  for (NSURL *URL in removedFiles) // When to replace a file, the system performs a deletion before copying, so we need to delay to check this is a file deletion or replacement
    [self delayHandleFile:URL];
  
  if (![addedFiles count] &&
      ![removedFiles count]){
    NSSet *setForEnum = [_scheduledFiles copy];
    for (NSURL *URL in setForEnum){
      if (![[NSFileManager defaultManager] fileExistsAtPath:[URL path]])
        continue;
      // Existence means it's a replacement file
      [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(confirmDeleteFile:) object:URL];
      [self monitorCopyingFile:URL isReplacement:YES];
      [_scheduledFiles removeObject:URL];
    }
  }
  
  _lastFileURLs = curFiles;
}

- (void)monitorCopyingFile:(NSURL *)fileURL
             isReplacement:(BOOL)isReplacement
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _copyingFileInfos = [@{} mutableCopy];
  });
  
  if (_copyingFileInfos[fileURL])
    return;
  
  _CXACopyingFileInfo *info = [_CXACopyingFileInfo new];
  info.fileURL = fileURL;
  info.watcher = self;
  _SourceContext *ctx = malloc(sizeof(_SourceContext));
  ctx->token = &_kFileSourceToken;
  ctx->isReplacement = isReplacement;
  ctx->watcher = self;
  ctx->fileURL = info.fileURL; // let info retain fileURL for us
  int fd = open([[fileURL path] fileSystemRepresentation], O_EVTONLY);
  dispatch_source_t dsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_ATTRIB, _watcherQueue);
  dispatch_set_context(dsrc, ctx);
  dispatch_source_set_event_handler_f(dsrc, _sourceFunc);
  dispatch_source_set_cancel_handler(dsrc, ^{
    [info stopPoll];
    close(fd);
    free(ctx);
  });
  
  info.source = dsrc;
  dispatch_resume(dsrc);
  _copyingFileInfos[fileURL] = info;
}

- (void)finishCopyingFile:(NSURL *)fileURL
{
  _CXACopyingFileInfo *info = _copyingFileInfos[fileURL];  
  _SourceContext *ctx = dispatch_get_context(info.source);
  BOOL confirmAndResponds = [self.delegate conformsToProtocol:@protocol(CXADirectoryContentsWatcherDelegate)] &&
  [self.delegate respondsToSelector:@selector(directoryWatcher:didFinishCopyItemAtURL:isReplacement:)];
  if (confirmAndResponds || self.finishCopyHandler){
    BOOL isReplacement = ctx->isReplacement;
    [self.delegate directoryWatcher:self didFinishCopyItemAtURL:fileURL isReplacement:isReplacement];
    if (self.finishCopyHandler)
      self.finishCopyHandler(fileURL, isReplacement);
  }

  dispatch_source_cancel(info.source);
  [_copyingFileInfos removeObjectForKey:fileURL];
}

- (void)delayHandleFile:(NSURL *)fileURL
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _scheduledFiles = [NSMutableSet set];
  });
  
  [_scheduledFiles addObject:fileURL];
  [self performSelector:@selector(confirmDeleteFile:) withObject:fileURL afterDelay:1];
}

- (void)confirmDeleteFile:(id)fileURL
{
  BOOL confirmAndResponds = [self.delegate conformsToProtocol:@protocol(CXADirectoryContentsWatcherDelegate)] &&
  [self.delegate respondsToSelector:@selector(directoryWatcher:didRemoveItemAtURL:)];
  if (confirmAndResponds || self.removeItemHandler) {
    [self.delegate directoryWatcher:self didRemoveItemAtURL:fileURL];
    if (self.removeItemHandler)
      self.removeItemHandler(fileURL);
  }
  
  [_scheduledFiles removeObject:fileURL];
}

// To elminate compile warnings, must put this before @end
static void _sourceFunc(void *context){
  _SourceContext *ctx = (_SourceContext *)context;
  CXADirectoryContentsWatcher *self = ctx->watcher;
  if (ctx->token == &_kDirSourceToken){
    [self handleDirContentsChange];
  } else if (ctx->token == &_kFileSourceToken){
    [self->_copyingFileInfos[ctx->fileURL] poll];
    self->_lastFileURLs = [self fileURLs];
  }
}

@end

#define MAX_TRIES 10

@implementation _CXACopyingFileInfo

- (void)checkFinsihCopy
{
  NSUInteger fileSize = [self fileSize];
  BOOL pollAgain = YES;
  if (fileSize == 0){
    self.possibleZeroSizeFileCheckCounter++;
    if (self.possibleZeroSizeFileCheckCounter == MAX_TRIES){
      // This is a zero size file
      [self.watcher finishCopyingFile:self.fileURL];
      pollAgain = NO;
    }
  } else {
    if (fileSize == self.lastFileSize){
      [self.watcher finishCopyingFile:self.fileURL];
      pollAgain = NO;
    }
  }
  
  if (pollAgain)
    [self poll];
}

- (void)poll
{
  [self stopPoll];
  self.lastFileSize = [self fileSize];
  // DISPATCH_VNODE_ATTRIB send event at file will finish writting, if lucky, we can receive the event after copying job done, but not always especially on multiple files copying
  [self performSelector:@selector(checkFinsihCopy) withObject:nil afterDelay:.5];    
}

- (void)stopPoll
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkFinsihCopy) object:nil];
}

- (NSUInteger)fileSize
{
  NSNumber *fs;
  [self.fileURL getResourceValue:&fs forKey:NSURLFileSizeKey error:NULL];
  return [fs unsignedIntegerValue];
}

#if !defined(OS_OBJECT_USE_OBJC) || !OS_OBJECT_USE_OBJC
- (void)dealloc
{
  dispatch_release(_source);
}
#endif

@end
