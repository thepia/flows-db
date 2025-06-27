/**
 * Error reporting endpoint for the flows-admin-demo server
 * Logs error reports to console during development
 * 
 * Purpose: Provides a development endpoint for admin dashboard error reporting
 * Context: This enables debugging of Supabase issues, UI errors, and admin flow problems
 */

import { json } from '@sveltejs/kit';

export async function POST({ request }) {
	try {
		const errorReport = await request.json();
		
		// Log the error report with timestamp and formatting
		const timestamp = new Date().toISOString();
		const reportType = errorReport.type || 'unknown';
		
		console.log(`\n🚨 [${timestamp}] Admin Demo Error Report - ${reportType.toUpperCase()}`);
		console.log('═'.repeat(70));
		
		// Format different types of error reports
		switch (errorReport.type) {
			case 'admin-error':
				console.log(`🔧 Admin Error - ${errorReport.operation}`);
				if (errorReport.error) {
					console.log(`❌ Error: ${errorReport.error.message || errorReport.error}`);
					if (errorReport.error.name) console.log(`🏷️  Type: ${errorReport.error.name}`);
					if (errorReport.error.code) console.log(`🔢 Code: ${errorReport.error.code}`);
					if (errorReport.error.stack) console.log(`📚 Stack: ${errorReport.error.stack.split('\n')[0]}`);
				}
				break;
				
			case 'data-error':
				console.log(`🗄️  Database Error - ${errorReport.table}.${errorReport.operation}`);
				if (errorReport.error) {
					console.log(`❌ Error: ${errorReport.error.message || errorReport.error}`);
					if (errorReport.error.code) console.log(`🔢 Code: ${errorReport.error.code}`);
					if (errorReport.error.details) console.log(`📝 Details: ${errorReport.error.details}`);
					if (errorReport.error.hint) console.log(`💡 Hint: ${errorReport.error.hint}`);
				}
				console.log(`🏗️  Operation: ${errorReport.operation.toUpperCase()} on ${errorReport.table}`);
				break;
				
			case 'ui-error':
				console.log(`🎨 UI Error - ${errorReport.component}.${errorReport.action}`);
				if (errorReport.error) {
					console.log(`❌ Error: ${errorReport.error.message || errorReport.error}`);
					if (errorReport.error.name) console.log(`🏷️  Type: ${errorReport.error.name}`);
					if (errorReport.error.stack) console.log(`📚 Stack: ${errorReport.error.stack.split('\n')[0]}`);
				}
				console.log(`🧩 Component: ${errorReport.component}`);
				console.log(`⚡ Action: ${errorReport.action}`);
				break;
				
			default:
				console.log(`📋 Unknown Report Type:`, errorReport);
		}
		
		// Log context if available
		if (errorReport.context && Object.keys(errorReport.context).length > 0) {
			console.log(`🔍 Context:`, errorReport.context);
		}
		
		// Log technical details
		if (errorReport.userAgent) {
			const uaShort = errorReport.userAgent.includes('Chrome') ? 'Chrome' :
			               errorReport.userAgent.includes('Firefox') ? 'Firefox' :
			               errorReport.userAgent.includes('Safari') ? 'Safari' : 'Unknown';
			console.log(`🌐 Browser: ${uaShort}`);
		}
		if (errorReport.url) {
			console.log(`📍 URL: ${errorReport.url}`);
		}
		if (errorReport.app) {
			console.log(`📱 App: ${errorReport.app} v${errorReport.version || '1.0.0'}`);
		}
		
		console.log('═'.repeat(70));
		
		return json({ 
			success: true, 
			message: 'Admin error report logged successfully',
			timestamp,
			type: reportType
		});
		
	} catch (error) {
		console.error('❌ [Admin Error Reporting] Failed to process error report:', error);
		
		return json({ 
			success: false, 
			message: 'Failed to process admin error report',
			error: error.message 
		}, { status: 500 });
	}
}

// GET endpoint for health check
export async function GET() {
	return json({
		status: 'healthy',
		service: 'flows-admin-demo-error-reporting',
		timestamp: new Date().toISOString(),
		endpoints: {
			POST: 'Submit admin error reports',
			GET: 'Health check'
		}
	});
}