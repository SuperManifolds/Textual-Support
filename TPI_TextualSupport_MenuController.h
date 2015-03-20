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
- (void)unbanUserFromChannel:(id)sender;
- (void)kickUserFromChannel:(id)sender;
- (void)kickBanUserFromChannel:(id)sender;
- (void)muteUserOnChannel:(id)sender;
- (void)unmuteUserOnChannel:(id)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)item;

@end
