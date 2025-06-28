<script lang="ts">
import type { Invitation } from '$lib/types';

export let status: Invitation['status'];
export const size: 'sm' | 'md' | 'lg' = 'md';

// Size mappings
$: sizeClasses = {
  sm: 'px-1.5 py-0.5 text-xs',
  md: 'px-2.5 py-0.5 text-xs',
  lg: 'px-3 py-1 text-sm',
}[size];

// Status color mappings
$: statusClasses =
  {
    pending: 'text-yellow-600 bg-yellow-50 border-yellow-200',
    used: 'text-green-600 bg-green-50 border-green-200',
    expired: 'text-red-600 bg-red-50 border-red-200',
    revoked: 'text-gray-600 bg-gray-50 border-gray-200',
  }[status] || 'text-gray-600 bg-gray-50 border-gray-200';

// Status display text (capitalize first letter)
$: displayText = status.charAt(0).toUpperCase() + status.slice(1);
</script>

<span 
	class="inline-flex items-center rounded-full border font-medium {sizeClasses} {statusClasses}"
	title="Invitation status: {displayText}"
>
	{displayText}
</span>