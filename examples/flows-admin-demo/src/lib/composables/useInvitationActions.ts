import type { Invitation } from "$lib/types";

/**
 * Composable for managing invitation actions across components
 * Provides consistent invitation management logic that can be reused
 * in dashboard, invitation list, and other components
 */
export function useInvitationActions() {
	
	/**
	 * Share invitation code by copying to clipboard
	 */
	async function shareInvitationCode(invitationCode: string): Promise<boolean> {
		try {
			await navigator.clipboard.writeText(invitationCode);
			console.log(`Shared invitation code: ${invitationCode}`);
			// TODO: Show toast notification
			return true;
		} catch (error) {
			console.error('Failed to copy invitation code:', error);
			// TODO: Show error toast
			return false;
		}
	}

	/**
	 * View detailed invitation information
	 * TODO: Open modal with full invitation details
	 */
	function viewInvitationDetails(invitation: Invitation): void {
		console.log('Viewing invitation details:', invitation);
		// TODO: Implement modal or navigation to detail view
	}

	/**
	 * Resend an existing invitation
	 * TODO: Implement actual API call to resend
	 */
	async function resendInvitation(invitation: Invitation): Promise<boolean> {
		try {
			console.log('Resending invitation:', invitation);
			// TODO: Call API to resend invitation
			// const result = await api.invitations.resend(invitation.id);
			// TODO: Show success toast
			return true;
		} catch (error) {
			console.error('Failed to resend invitation:', error);
			// TODO: Show error toast
			return false;
		}
	}

	/**
	 * Revoke an invitation with confirmation
	 */
	async function revokeInvitation(invitation: Invitation): Promise<boolean> {
		const confirmed = confirm(
			`Are you sure you want to revoke the invitation for ${invitation.firstName} ${invitation.lastName}?`
		);
		
		if (!confirmed) return false;

		try {
			console.log('Revoking invitation:', invitation);
			// TODO: Call API to revoke invitation
			// const result = await api.invitations.revoke(invitation.id);
			// TODO: Update local state
			// TODO: Show success toast
			return true;
		} catch (error) {
			console.error('Failed to revoke invitation:', error);
			// TODO: Show error toast
			return false;
		}
	}

	/**
	 * Recreate an expired invitation
	 * TODO: Implement recreation logic
	 */
	async function recreateInvitation(invitation: Invitation): Promise<boolean> {
		try {
			console.log('Recreating invitation:', invitation);
			// TODO: Call API to create new invitation with same data
			// const result = await api.invitations.create({...invitation});
			// TODO: Show success toast
			return true;
		} catch (error) {
			console.error('Failed to recreate invitation:', error);
			// TODO: Show error toast
			return false;
		}
	}

	/**
	 * Get available actions for an invitation based on its status
	 */
	function getAvailableActions(invitation: Invitation) {
		const actions = [];

		// View details is always available
		actions.push({
			id: 'view',
			label: 'View Details',
			icon: 'Eye',
			handler: () => viewInvitationDetails(invitation),
			destructive: false
		});

		// Share code if invitation has a code
		if (invitation.invitationCode) {
			actions.push({
				id: 'share',
				label: 'Share Invitation Code',
				icon: 'Share',
				handler: () => shareInvitationCode(invitation.invitationCode),
				destructive: false
			});
		}

		// Status-specific actions
		switch (invitation.status) {
			case 'pending':
				actions.push({
					id: 'resend',
					label: 'Resend',
					icon: 'RefreshCw',
					handler: () => resendInvitation(invitation),
					destructive: false
				});
				actions.push({
					id: 'revoke',
					label: 'Revoke',
					icon: 'XCircle',
					handler: () => revokeInvitation(invitation),
					destructive: true
				});
				break;

			case 'expired':
				actions.push({
					id: 'recreate',
					label: 'Recreate',
					icon: 'RefreshCw',
					handler: () => recreateInvitation(invitation),
					destructive: false
				});
				break;

			// For 'used' and 'revoked' status, only view and share are available
		}

		return actions;
	}

	/**
	 * Execute an action by ID
	 */
	async function executeAction(actionId: string, invitation: Invitation): Promise<boolean> {
		const actions = getAvailableActions(invitation);
		const action = actions.find(a => a.id === actionId);
		
		if (!action) {
			console.error(`Action ${actionId} not found for invitation`, invitation);
			return false;
		}

		return await action.handler();
	}

	return {
		// Individual action functions
		shareInvitationCode,
		viewInvitationDetails,
		resendInvitation,
		revokeInvitation,
		recreateInvitation,
		
		// Helper functions
		getAvailableActions,
		executeAction
	};
}