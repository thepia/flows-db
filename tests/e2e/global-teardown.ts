import type { FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  console.log('🛑 Shutting down flows-admin-demo server...');

  // Kill any remaining demo server processes
  try {
    const { exec } = await import('child_process');
    const { promisify } = await import('util');
    const execAsync = promisify(exec);

    // Find and kill any processes running on port 5173 (flows-admin-demo default)
    try {
      const { stdout } = await execAsync('lsof -ti:5173');
      if (stdout.trim()) {
        const pids = stdout.trim().split('\n');
        for (const pid of pids) {
          try {
            await execAsync(`kill -9 ${pid}`);
            console.log(`🔪 Killed process ${pid} on port 5173`);
          } catch (error) {
            console.log(`⚠️  Could not kill process ${pid}: ${error}`);
          }
        }
      }
    } catch (error) {
      console.log('ℹ️  No processes found on port 5173');
    }

    console.log('✅ Cleanup completed');
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
}

export default globalTeardown;
