import type { DemoSettings } from '$lib/types';

const SETTINGS_KEY = 'flows-admin-demo-settings';

export class LocalStorageManager {
	/**
	 * Save settings to localStorage
	 */
	static saveSettings(settings: DemoSettings): void {
		try {
			const serialized = JSON.stringify({
				...settings,
				lastUpdated: new Date().toISOString()
			});
			localStorage.setItem(SETTINGS_KEY, serialized);
		} catch (error) {
			console.error('Failed to save settings to localStorage:', error);
		}
	}

	/**
	 * Load settings from localStorage
	 */
	static loadSettings(): DemoSettings | null {
		try {
			const stored = localStorage.getItem(SETTINGS_KEY);
			if (!stored) return null;
			
			const parsed = JSON.parse(stored);
			
			// Validate the structure
			if (!this.isValidSettings(parsed)) {
				console.warn('Invalid settings structure found in localStorage, clearing...');
				this.clearSettings();
				return null;
			}
			
			return parsed as DemoSettings;
		} catch (error) {
			console.error('Failed to load settings from localStorage:', error);
			return null;
		}
	}

	/**
	 * Clear settings from localStorage
	 */
	static clearSettings(): void {
		try {
			localStorage.removeItem(SETTINGS_KEY);
		} catch (error) {
			console.error('Failed to clear settings from localStorage:', error);
		}
	}

	/**
	 * Check if the browser supports localStorage
	 */
	static isSupported(): boolean {
		try {
			const test = '__localStorage_test__';
			localStorage.setItem(test, 'test');
			localStorage.removeItem(test);
			return true;
		} catch {
			return false;
		}
	}

	/**
	 * Validate settings structure
	 */
	private static isValidSettings(obj: any): obj is DemoSettings {
		return (
			obj &&
			typeof obj === 'object' &&
			typeof obj.selectedBranding === 'string' &&
			typeof obj.selectedClient === 'string' &&
			typeof obj.allowRealClients === 'boolean' &&
			Array.isArray(obj.availableBrandings) &&
			typeof obj.lastUpdated === 'string'
		);
	}

	/**
	 * Get default settings
	 */
	static getDefaultSettings(): DemoSettings {
		return {
			selectedBranding: 'thepia-default',
			selectedClient: '',
			allowRealClients: false,
			availableBrandings: [
				{
					id: 'thepia-default',
					name: '@thepia/branding',
					displayName: 'Thepia (Default)',
					type: 'package',
					path: '@thepia/branding',
					isDefault: true
				}
			],
			lastUpdated: new Date().toISOString()
		};
	}

	/**
	 * Merge settings with defaults (useful for migrations)
	 */
	static mergeWithDefaults(settings: Partial<DemoSettings>): DemoSettings {
		const defaults = this.getDefaultSettings();
		return {
			...defaults,
			...settings,
			lastUpdated: new Date().toISOString()
		};
	}
}