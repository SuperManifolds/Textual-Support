#import "TextualApplication.h"

@interface TPI_TextualSupport: NSObject <THOPluginProtocol>

- (void)pluginLoadedIntoMemory;
- (NSArray *)subscribedServerInputCommands;
- (void)didReceiveServerInputOnClient:(IRCClient *)client
                    senderInformation:(NSDictionary *)senderDict
                   messageInformation:(NSDictionary *)messageDict;

+ (NSMutableArray *)muteListForChannel:(NSString *)channel onClient:(IRCClient *)client;

@end
