#import "TPI_TextualSupport.h"
#import "TPI_TextualSupport_MenuController.h"
#import "TPI_TextualSupportHelper.h"

@implementation TPI_TextualSupport

NSMenu *userlistMenu;
NSMenu *inputFieldMenu;
NSDictionary *messageCacheForSupportChannel;
NSMutableDictionary *serverSoftwareList;
BOOL isReceivingBanMessages;
BOOL isReceivingMuteMessages;


static NSMutableDictionary *banList;
static NSMutableDictionary *muteList;

-  (NSArray *)subscribedServerInputCommands {
    return @[@"join", @"part", @"004", @"728", @"729", @"367", @"368"];
}

- (NSArray *)serverSoftwareWithMuteSupport {
    return @[@"irc-seven", @"inspircd"];
}


- (void)pluginLoadedIntoMemory {
	userlistMenu = menuController().userControlMenu;
    serverSoftwareList = [[NSMutableDictionary alloc] init];
    banList = [[NSMutableDictionary alloc] init];
    muteList = [[NSMutableDictionary alloc] init];
    
    [self overrideExistingMenuItems];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource: @"messages" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    
    NSMenuItem *textualSupportMenuItems = [[NSMenuItem alloc] init];
	[textualSupportMenuItems setTitle:@"Textual Support"];
	[textualSupportMenuItems setKeyEquivalent:@""];
    NSMenu *textualSupportMenu = [NSMenu new];
	[textualSupportMenu setTitle:@"Textual Support"];
    NSArray *supportMessages = dict[@"userlist"];
    [TPI_TextualSupportHelper addItemsFromDictionaryToMenu:textualSupportMenu menuItems:supportMessages selector:@selector(postMenuMessage:)];
    [textualSupportMenuItems setSubmenu: textualSupportMenu];
	[userlistMenu addItem:[textualSupportMenuItems copy]];
    
    NSInteger indexOfBanItem = [userlistMenu indexOfItemWithTitle:@"Ban"];
    
    NSMenuItem *textualUnbanUserMenuItem = [[NSMenuItem alloc] init];
    [textualUnbanUserMenuItem setTitle:@"Unban"];
    [textualUnbanUserMenuItem setKeyEquivalent:@""];
    [textualUnbanUserMenuItem setTarget:menuController()];
    [textualUnbanUserMenuItem setAction:@selector(unbanUserFromChannel:)];
    [textualUnbanUserMenuItem setTag:424201];
    [userlistMenu insertItem:textualUnbanUserMenuItem atIndex:(indexOfBanItem + 1)];
    
    NSMenuItem *textualMuteUserMenuItem = [[NSMenuItem alloc] init];
    [textualMuteUserMenuItem setTitle:@"Mute"];
    [textualMuteUserMenuItem setKeyEquivalent:@""];
    [textualMuteUserMenuItem setTarget:menuController()];
    [textualMuteUserMenuItem setAction:@selector(muteUserOnChannel:)];
    [textualMuteUserMenuItem setTag:424202];
    [userlistMenu insertItem:textualMuteUserMenuItem atIndex:(indexOfBanItem + 2)];
    
    
    NSMenuItem *textualUnmuteUserMenuItem = [[NSMenuItem alloc] init];
    [textualUnmuteUserMenuItem setTitle:@"Unmute"];
    [textualUnmuteUserMenuItem setKeyEquivalent:@""];
    [textualUnmuteUserMenuItem setTarget:menuController()];
    [textualUnmuteUserMenuItem setAction:@selector(unmuteUserOnChannel:)];
    [userlistMenu insertItem:textualUnmuteUserMenuItem atIndex:(indexOfBanItem + 3)];
    
    menuController().userControlMenu = userlistMenu;
}

- (void)overrideExistingMenuItems {
    [[userlistMenu itemWithTag:1503] setAction:@selector(giveOperatorStatusToUser:)];
    [[userlistMenu itemWithTag:1505] setAction:@selector(giveVoiceStatusToUser:)];
    
    [[userlistMenu itemWithTag:1507] setAction:@selector(revokeOperatorStatusFromUser:)];
    [[userlistMenu itemWithTag:1509] setAction:@selector(revokeVoiceStatusFromUser:)];
    
    [[userlistMenu itemWithTag:1511] setAction:@selector(banUserFromChannel:)];
    [[userlistMenu itemWithTag:1512] setAction:@selector(kickUserFromChannel:)];
    [[userlistMenu itemWithTag:1513] setAction:@selector(kickBanUserFromChannel:)];
}

- (void)didReceiveServerInput:(THOPluginDidReceiveServerInputConcreteObject *)inputObject onClient:(IRCClient *)client {
    NSString *command = [inputObject messageCommand];
    
    if ([command isEqualToString:@"004"]) {
        NSString *serverSoftware = [inputObject messageSequence];
        [serverSoftwareList setObject:serverSoftware forKey:[client uniqueIdentifier]];
    }
    
    else if ([command isEqualToString:@"JOIN"]) {
        NSString *channel = [inputObject messageParamaters][0];
        if ([inputObject.senderNickname isEqualIgnoringCase:[client localNickname]] == NO) return;
        
        if ([banList objectForKey:[client uniqueIdentifier]] == nil) {
            [banList setObject:[[NSMutableDictionary alloc] init] forKey:[client uniqueIdentifier]];
        }
        
        if ([muteList objectForKey:[client uniqueIdentifier]] == nil) {
            [muteList setObject:[[NSMutableDictionary alloc] init] forKey:[client uniqueIdentifier]];
        }
        
        [client sendCommand:[NSString stringWithFormat:@"MODE %@ +b", channel]];
        if ([self serverSupportsMute:client]) {
            [client sendCommand:[NSString stringWithFormat:@"MODE %@ +q", channel]];
        }
    } else if ([command isEqualToString:@"367"]) {
        NSString *channel = inputObject.messageParamaters[1];
        NSMutableDictionary *banChannels = [banList objectForKey:[client uniqueIdentifier]];
        
        if (isReceivingBanMessages == NO) {
            [banChannels setObject:[[NSMutableArray alloc] init] forKey:channel];
            isReceivingBanMessages = YES;
        }
        
        NSMutableArray *bans = [banChannels objectForKey:channel];
        [bans addObject:inputObject.messageParamaters[2]];
        [banChannels setObject:bans forKey:channel];
        [banList setObject:banChannels forKey:[client uniqueIdentifier]];
    } else if ([command isEqualToString:@"368"]) {
        isReceivingBanMessages = NO;
    } else if ([command isEqualToString:@"728"]) {
        NSString *channel = inputObject.messageParamaters[1];
        NSMutableDictionary *muteChannels = [muteList objectForKey:[client uniqueIdentifier]];
        
        if (isReceivingMuteMessages == NO) {
            [muteChannels setObject:[[NSMutableArray alloc] init] forKey:channel];
            isReceivingMuteMessages = YES;
        }
        
        NSMutableArray *mutes = [muteChannels objectForKey:channel];
        [mutes addObject:inputObject.messageParamaters[2]];
        [muteChannels setObject:mutes forKey:channel];
        
        [muteList setObject:muteChannels forKey:[client uniqueIdentifier]];
    } else if ([command isEqualToString:@"729"]) {
        isReceivingMuteMessages = NO;
    }

}

- (BOOL)serverSupportsMute:(IRCClient *)client {
    NSString *currentServerSoftware = [serverSoftwareList objectForKey:[client uniqueIdentifier]];
    for (NSString *serverSoftware in self.serverSoftwareWithMuteSupport) {
        if ([serverSoftware containsIgnoringCase:currentServerSoftware]) return YES;
    }
    return YES;
}


+ (NSMutableArray *)banListForChannel:(NSString *)channel onClient:(IRCClient *)client {
    NSMutableDictionary *channels = [banList objectForKey:[client uniqueIdentifier]];
    return [channels objectForKey:channel];
}

+ (NSMutableArray *)muteListForChannel:(NSString *)channel onClient:(IRCClient *)client {
    NSLog(@"mute list: %@", muteList);
    NSMutableDictionary *channels = [muteList objectForKey:[client uniqueIdentifier]];
    return [channels objectForKey:channel];
}

@end
