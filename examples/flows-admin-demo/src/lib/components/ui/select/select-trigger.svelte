<script lang="ts">
import { cn } from '$lib/utils.js';
import { ChevronDown } from 'lucide-svelte';

let {
  ref = $bindable(null),
  class: className,
  children,
  ...restProps
}: {
  ref?: HTMLDivElement | null;
  class?: string;
  children?: any;
  [key: string]: any;
} = $props();
</script>

<div
	bind:this={ref}
	class={cn(
		"border-input bg-background ring-offset-background data-[placeholder]:text-muted-foreground focus:ring-ring flex h-10 w-full items-center justify-between rounded-md border px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 [&>span]:line-clamp-1",
		className
	)}
	{...restProps}
>
	{@render children?.()}
	<ChevronDown class="size-4 opacity-50" />
</div>
