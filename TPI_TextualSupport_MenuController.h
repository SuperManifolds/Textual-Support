#include "TPI_TextualSupport.h"
#include "TPI_TextualSupportHelper.h"

@interface TXMenuController (TPI_TextualSupport_MenuController)
- (void)postMenuMessage:(id)sender;
- (void)postLinkToInputField:(id)sender;

- (void)giveOperatorStatusToUser:(id)sender;
- (void)giveVoiceStatusToUser:(id)sender;
- (void)revokeOperatorStatusFromUser:(id)sender;
- (void)revokeVoiceStatusFromUser:(id)sender;

- (void)banUserFromChannel:(id)sender;
- (void)kickUserFromChannel:(id)sender;
- (void)kickBanUserFromChannel:(id)sender;

- (void)trackUserInitiated:(id)sender;
- (void)trackUserStopped:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)item;

@end
