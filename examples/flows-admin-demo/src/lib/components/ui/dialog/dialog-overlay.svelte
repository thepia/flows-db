<script lang="ts">
import { cn } from '$lib/utils.js';
import type { Dialog as DialogPrimitive } from 'bits-ui';

let {
  ref = $bindable(null),
  class: className,
  ...restProps
}: DialogPrimitive.OverlayProps = $props();
</script>

<DialogPrimitive.Overlay
	bind:ref
	class={cn(
		"data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0  fixed inset-0 z-50 bg-black/80",
		className
	)}
	{...restProps}
/>
