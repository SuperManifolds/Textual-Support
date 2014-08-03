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
    [newMenuItem setKeyEquivalent:NSStringEmptyPlaceholder];
    [newMenuItem setRepresentedObject: message];
    [newMenuItem setTarget:menuController()];
    [newMenuItem setAction:anAction];
    [parentMenu addItem:[newMenuItem copy]];
}

+ (BOOL)userIsChannelRegular:(NSString *)nickname {
    
    return NO;
}



@end
