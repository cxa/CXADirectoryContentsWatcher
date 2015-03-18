# CXADirectoryContentsWatcher

To handle files added or removed from iTunes File Sharing while app running motivates me to create this project.

Watching for the changes of a directory contents is easy with GCD `dispatch_source_t`, but to determine whether a file finished copying or not is very hard. With `DISPATCH_VNODE_ATTRIB` mask, the source will send an event when file will finish, if lucky we can receive another event after the copying is completely finished, but not always especially there are multiple files copying. So I do it the hard way, poll to check file size changing, when current size is equal to last check, I assume the copying job is done.

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

* Twitter: [@_cxa](https://twitter.com/_cxa)
* Apps available on the App Store: <http://lazyapps.com>
* PayPal: xianan.chen+paypal 📧 gmail.com, buy me a cup of coffee if you find it's useful for you.

## License

CXADirectoryContentsWatcher is released under the MIT license. In short, it's royalty-free but you must you keep the copyright notice in your code or software distribution.

For non attributed commercial lisence, please contact.
