#import "TextualApplication.h"

@interface TPI_TextualSupport: NSObject <THOPluginProtocol>

- (void)pluginLoadedIntoMemory;
- (NSArray *)subscribedServerInputCommands;
- (void)didReceiveServerInput:(THOPluginDidReceiveServerInputConcreteObject *)inputObject onClient:(IRCClient *)client;

+ (NSMutableArray *)muteListForChannel:(NSString *)channel onClient:(IRCClient *)client;
+ (NSMutableArray *)banListForChannel:(NSString *)channel onClient:(IRCClient *)client;

@end
