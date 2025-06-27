# Floating Status System - Design & Planning

## Overview

The Floating Status System provides real-time monitoring and debugging capabilities for the Flows Admin Demo application. It replaces the inline error reporting card with a non-intrusive floating button that expands into a comprehensive status dashboard.

## Current Implementation

### Components
- `FloatingStatusButton.svelte` - Main component with status monitoring and popover
- Integrated into dashboard (`+page.svelte`) as floating element
- Self-contained with auto-refresh capabilities

### Current Status Monitors
1. **Error Reporting**
   - Queue size monitoring
   - Server endpoint status
   - Debug mode indicator
   - Manual flush and testing capabilities

2. **Authentication** (Basic)
   - Supabase connection status
   - Demo mode indicator

3. **Database** (Basic)
   - Connection status
   - Current client context

4. **Service Worker** (Placeholder)
   - Not yet implemented

## Future Enhancements

### Phase 1: Enhanced Status Monitoring

#### 1.1 Real Authentication Status
```typescript
interface AuthStatus {
  status: 'authenticated' | 'anonymous' | 'expired' | 'error';
  user?: {
    id: string;
    email: string;
    role: string;
  };
  session?: {
    expiresAt: Date;
    refreshToken: boolean;
  };
  connection: 'connected' | 'disconnected' | 'retrying';
}
```

#### 1.2 Enhanced Database Monitoring
```typescript
interface DatabaseStatus {
  connection: 'connected' | 'disconnected' | 'slow' | 'error';
  latency?: number; // ms
  lastQuery?: Date;
  activeConnections?: number;
  realtimeStatus: {
    connected: boolean;
    channels: string[];
    subscriptions: number;
  };
}
```

#### 1.3 Service Worker Implementation
```typescript
interface ServiceWorkerStatus {
  supported: boolean;
  status: 'installing' | 'waiting' | 'active' | 'redundant' | 'none';
  version?: string;
  updateAvailable: boolean;
  lastUpdate?: Date;
  cacheStatus: {
    size: number;
    lastCleared: Date;
  };
}
```

### Phase 2: Performance Monitoring

#### 2.1 Application Performance
```typescript
interface PerformanceMetrics {
  pageLoad: {
    domContentLoaded: number;
    fullyLoaded: number;
    timeToInteractive: number;
  };
  navigation: {
    routeChanges: number;
    averageNavigationTime: number;
    slowestRoute: string;
  };
  memory: {
    usedJSHeapSize: number;
    totalJSHeapSize: number;
    jsHeapSizeLimit: number;
  };
}
```

#### 2.2 Network Monitoring
```typescript
interface NetworkStatus {
  online: boolean;
  connectionType: string; // '4g', 'wifi', etc.
  effectiveType: string; // 'slow-2g', '2g', '3g', '4g'
  downlink: number; // Mbps
  rtt: number; // ms
  apiCalls: {
    total: number;
    successful: number;
    failed: number;
    averageResponseTime: number;
  };
}
```

### Phase 3: Developer Tools Integration

#### 3.1 Console Log Capture
- Capture and display recent console logs
- Filter by log level (error, warn, info, debug)
- Export logs for debugging

#### 3.2 API Request Inspector
```typescript
interface APIRequest {
  id: string;
  timestamp: Date;
  method: string;
  url: string;
  status: number;
  responseTime: number;
  requestBody?: any;
  responseBody?: any;
  headers: Record<string, string>;
}
```

#### 3.3 State Inspector
- View current Svelte store states
- Track state changes over time
- Export state snapshots

### Phase 4: User Experience Enhancements

#### 4.1 Status History
- Timeline view of status changes
- Incident tracking and resolution
- Performance trend graphs

#### 4.2 Notification System
```typescript
interface StatusNotification {
  id: string;
  type: 'error' | 'warning' | 'info' | 'success';
  title: string;
  message: string;
  timestamp: Date;
  persistent: boolean;
  actions?: {
    label: string;
    action: () => void;
  }[];
}
```

#### 4.3 Customizable Dashboard
- User preferences for status sections
- Collapsible sections
- Draggable status cards
- Theme customization

### Phase 5: Advanced Features

#### 5.1 Remote Monitoring
- Send status data to monitoring service
- Team-wide status dashboard
- Alerting system for critical issues

#### 5.2 Automated Issue Resolution
```typescript
interface AutoResolution {
  trigger: {
    condition: string;
    threshold: number;
  };
  actions: {
    type: 'refresh' | 'reconnect' | 'flush' | 'custom';
    maxAttempts: number;
    cooldown: number; // ms
  }[];
}
```

#### 5.3 Integration Testing
- Automated health checks
- End-to-end test triggers
- Performance benchmarking

## Technical Architecture

### State Management
```typescript
// Central status store
interface SystemStatus {
  overall: 'healthy' | 'degraded' | 'critical';
  lastUpdate: Date;
  auth: AuthStatus;
  database: DatabaseStatus;
  serviceWorker: ServiceWorkerStatus;
  performance: PerformanceMetrics;
  network: NetworkStatus;
  errors: ErrorReport[];
  notifications: StatusNotification[];
}
```

### Component Structure
```
FloatingStatusButton.svelte
├── StatusPopover.svelte
│   ├── StatusSection.svelte (Error Reporting)
│   ├── StatusSection.svelte (Authentication)
│   ├── StatusSection.svelte (Database)
│   ├── StatusSection.svelte (Service Worker)
│   ├── StatusSection.svelte (Performance)
│   └── StatusActions.svelte
├── StatusStore.ts
├── StatusMonitors/
│   ├── AuthMonitor.ts
│   ├── DatabaseMonitor.ts
│   ├── ServiceWorkerMonitor.ts
│   ├── PerformanceMonitor.ts
│   └── NetworkMonitor.ts
└── StatusNotifications.svelte
```

### Data Flow
1. **Monitor Services** collect status data on intervals
2. **Status Store** aggregates and maintains current state
3. **Floating Button** displays overall health indicator
4. **Status Popover** shows detailed breakdown on demand
5. **Notification System** alerts users of critical issues

## Implementation Priorities

### Priority 1 (Immediate)
- [x] Basic floating button with popover
- [x] Error reporting integration
- [ ] Enhanced auth status monitoring
- [ ] Database latency monitoring

### Priority 2 (Short-term)
- [ ] Service worker implementation
- [ ] Basic performance metrics
- [ ] Console log capture
- [ ] Status history tracking

### Priority 3 (Medium-term)
- [ ] API request inspector
- [ ] Network monitoring
- [ ] Notification system
- [ ] State inspector

### Priority 4 (Long-term)
- [ ] Remote monitoring
- [ ] Automated issue resolution
- [ ] Advanced analytics
- [ ] Team collaboration features

## Configuration

### Environment Variables
```bash
# Status monitoring configuration
ENABLE_STATUS_MONITORING=true
STATUS_UPDATE_INTERVAL=5000
STATUS_HISTORY_RETENTION=86400000  # 24 hours in ms
ENABLE_PERFORMANCE_MONITORING=true
ENABLE_NETWORK_MONITORING=true

# Remote monitoring (future)
STATUS_REMOTE_ENDPOINT=https://status.thepia.com/api/reports
STATUS_TEAM_ID=your-team-id
```

### User Preferences
```typescript
interface StatusPreferences {
  position: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left';
  autoRefreshInterval: number;
  enabledSections: string[];
  notificationLevel: 'all' | 'warnings' | 'errors' | 'critical';
  persistHistory: boolean;
  compactMode: boolean;
}
```

## Security Considerations

1. **Data Privacy**: Ensure sensitive data is not exposed in status reports
2. **Access Control**: Limit status access to authorized developers only
3. **Data Sanitization**: Clean request/response data before logging
4. **Rate Limiting**: Prevent status monitoring from impacting performance
5. **Secure Storage**: Encrypt stored status history and user preferences

## Success Metrics

1. **Developer Productivity**
   - Reduced debugging time
   - Faster issue identification
   - Improved development workflow

2. **Application Reliability**
   - Faster incident response
   - Proactive issue detection
   - Reduced downtime

3. **User Experience**
   - Non-intrusive monitoring
   - Actionable insights
   - Clear status communication

## Conclusion

The Floating Status System will evolve from a simple error reporting tool into a comprehensive development and monitoring dashboard. By implementing these phases incrementally, we can provide immediate value while building toward a powerful debugging and monitoring solution.