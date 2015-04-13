//
//  TPI_TextualSupportHelper.m
//  TextualSupport
//
//  Created by Alex Sørlie Glomsaas on 02/08/2014.
//
//

#import "TPI_TextualSupportHelper.h"
#import "TPI_TextualSupport_MenuController.h"

@implementation TPI_TextualSupportHelper

+ (void)addItemsFromArrayToMenu:(NSMenu *)menu
                      menuItems:(NSArray *)menuItems
                       selector:(SEL)selector {
    
    for (NSDictionary *menuItem in menuItems) {
        if ([menuItem[@"Name"] isEqualToString: @"seperator"]) {
            [menu addItem:[NSMenuItem separatorItem]];
        }
        else {
            [self addMenuItemTitled:menuItem[@"Name"] withSelector:selector toMenu:menu message:menuItem[@"Message"]];
        }
    }
}

+ (void)addMenuItemTitled:(NSString *)title withSelector:(SEL)anAction toMenu:(NSMenu *)parentMenu message:(NSString *) message {
    NSMenuItem *newMenuItem = [[NSMenuItem alloc] init];
    [newMenuItem setTitle:title];
    [newMenuItem setKeyEquivalent:@""];
    [newMenuItem setRepresentedObject: message];
    [newMenuItem setTarget:menuController()];
    [newMenuItem setAction:anAction];
    [parentMenu addItem:[newMenuItem copy]];
}

+ (BOOL)userIsChannelRegular:(NSString *)nickname client:(IRCClient *)client channel:(IRCChannel *)channel {
    NSString *localNicknameOfUser = [client localNickname];
    if ([nickname isEqualToString:localNicknameOfUser]) {
        return YES;
    }
    if ([nickname isEqualIgnoringCase:@"milky"] || [nickname isEqualIgnoringCase:@"f0lder"]) {
        return YES;
    }
    return NO;
}

+ (NSArray *)listOfBansMatchingBanlist:(NSArray *)banList withUser:(IRCUser *)user {
    NSMutableArray *matchingBans = [[NSMutableArray alloc] init];
    NSLog(@"banlist: %@", banList);
    for (NSString *banMask in banList) {
        NSString *mutableBanMask = [banMask copy];
        if ([mutableBanMask hasPrefix:@"$"]) {
            NSRange endOfFlag = [mutableBanMask rangeOfString:@":"];
            mutableBanMask = [mutableBanMask substringWithRange:NSMakeRange(endOfFlag.location + 1, (mutableBanMask.length - (endOfFlag.location + 1)))];
        }
        
        NSLog(@"mask: %@", mutableBanMask);
        NSRange locationOfExtBan = [mutableBanMask rangeOfString:@"$"];
        if (locationOfExtBan.location != NSNotFound) {
            mutableBanMask = [mutableBanMask substringToIndex:locationOfExtBan.location];
        }
        
        if ([mutableBanMask length] == 0) continue;
        NSLog(@"host before regex: %@", mutableBanMask);
        NSString *regexHostmask = mutableBanMask;
        
        regexHostmask = [regexHostmask stringByReplacingOccurrencesOfString:@"?" withString:@"(.?)"];
        regexHostmask = [regexHostmask stringByReplacingOccurrencesOfString:@"*" withString:@"(.*?)"];
        regexHostmask = [NSString stringWithFormat:@"^%@$", regexHostmask];
        
        NSLog(@"Host after regex: %@", regexHostmask);
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexHostmask
                                                                               options:0
                                                                                 error:nil];
        
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:[user hostmask] options:0 range:NSMakeRange(0, [[user hostmask] length])];
        if (numberOfMatches > 0) {
            [matchingBans addObject:banMask];
        }
    }
    
    return matchingBans;
}

@end
