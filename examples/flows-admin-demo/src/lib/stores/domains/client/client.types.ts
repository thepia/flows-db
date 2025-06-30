export interface Client {
  client_id: string;
  client_code: string;
  legal_name: string;
  industry?: string;
  domain?: string;
  tier: 'free' | 'pro' | 'enterprise';
  status: 'active' | 'suspended' | 'inactive';
  created_at: string;
  updated_at: string;
}

export interface ClientState {
  clients: Client[];
  currentClient: Client | null;
  loading: boolean;
  error: string | null;
}

export interface ClientActions {
  loadAllClients: () => Promise<void>;
  selectClient: (clientId: string) => Promise<void>;
  refreshCurrentClient: () => Promise<void>;
}

export interface ClientStore extends ClientState {
  // Derived stores
  availableClients: Client[];
  clientsByTier: Record<string, Client[]>;
  
  // Actions
  actions: ClientActions;
}