#import "TextualApplication.h"

@interface TPI_TextualSupport: NSObject <THOPluginProtocol>
- (void)pluginLoadedIntoMemory;
- (void)didPostNewMessageForViewController:(TVCLogController *)logController
                               messageInfo:(NSDictionary *)messageInfo
                             isThemeReload:(BOOL)isThemeReload
                           isHistoryReload:(BOOL)isHistoryReload;
@end
