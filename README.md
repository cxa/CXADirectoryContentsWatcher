# CXADirectoryContentsWatcher

Needing to handle files added from iTunes File Sharing motivate me to create this project.

Watch for the changes of a directory contents is easy with GCD `dispatch_source_t`, but to determine whether a file finish copying or not is very hard. I've tried `DISPATCH_VNODE_ATTRIB` mask but without lucky. So I do it the hard way, poll to check file size changing, when current size is equal to last check, I assume the copying job is done.

Any suggestion is welcome, seeking for the elegant solutions.


## Header at a glance

    @protocol CXADirectoryContentsWatcherDelegate <NSObject>
    
    - (void)directoryWatcher:(CXADirectoryContentsWatcher *)dirWatcher didFinishCopyItemAtURL:(NSURL *)fileURL isReplacement:(BOOL)isReplacement;
    - (void)directoryWatcher:(CXADirectoryContentsWatcher *)dirWatcher didRemoveItemAtURL:(NSURL *)fileURL;
    
    @end
    
    @interface CXADirectoryContentsWatcher : NSObject
    
    @property (nonatomic, weak) id <CXADirectoryContentsWatcherDelegate> delegate;
    @property (nonatomic, strong, readonly) NSURL *directoryURL;
    
    - (instancetype)initWithDirectoryURL:(NSURL *)dirURL delegate:(id <CXADirectoryContentsWatcherDelegate>)delegate;
    - (BOOL)start;
    - (void)stop;
    
    @end

## Creator

* GitHub: <https://github.com/cxa>
* Twitter: [@_cxa](https://twitter.com/_cxa)
* Apps available in App Store: <http://lazyapps.com>

## License

CXADirectoryContentsWatcher is released under the MIT license. In short, it's royalty-free but you must you keep the copyright notice in your code or software distribution.
