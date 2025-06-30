// Debug script to test client switching
// Run this in the browser console to test the client switcher

console.log('🔧 Debug: Testing client switcher...');

// Check if stores are available
if (typeof window !== 'undefined') {
  console.log('✅ Browser environment detected');
  
  // Test accessing the client switcher
  window.testClientSwitch = async function(clientCode) {
    console.log(`🔄 Testing switch to client: ${clientCode}`);
    
    try {
      // Import the switcher
      const { demoClientSwitcher } = await import('/src/lib/orchestrators/demo-client-switcher.js');
      
      // Find the client
      const clients = await demoClientSwitcher.getAvailableClients();
      console.log('📋 Available clients:', clients.map(c => c.client_code));
      
      const targetClient = clients.find(c => c.client_code === clientCode);
      if (!targetClient) {
        console.error(`❌ Client ${clientCode} not found`);
        return;
      }
      
      console.log(`🎯 Found target client:`, targetClient);
      
      // Perform the switch
      await demoClientSwitcher.switchDemoClient(targetClient.client_id);
      
      console.log(`✅ Switch to ${clientCode} completed`);
      
    } catch (error) {
      console.error('❌ Switch failed:', error);
    }
  };
  
  // Test function
  console.log('💡 Usage: testClientSwitch("hygge-hvidlog") or testClientSwitch("meridian-brands")');
  
} else {
  console.log('❌ Not in browser environment');
}