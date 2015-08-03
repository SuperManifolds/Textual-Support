//
//  TPI_TextualSupportHelper.h
//  TextualSupport
//
//  Created by Alex Sørlie Glomsaas on 02/08/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "TextualApplication.h"

@interface TPI_TextualSupportHelper : NSObject
+ (void)addItemsFromDictionaryToMenu:(NSMenu *)menu menuItems:(NSDictionary *)menuItems selector:(SEL)selector;

+ (void)addMenuItemTitled:(NSString *)title
             withSelector:(SEL)anAction
                   toMenu:(NSMenu *)parentMenu
                  message:(NSString *)message;

+ (BOOL)userIsChannelRegular:(NSString *)nickname client:(IRCClient *)client channel:(IRCChannel *)channel;
+ (NSArray *)listOfBansMatchingBanlist:(NSArray *)banList withUser:(IRCUser *)user;

@end
