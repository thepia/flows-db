<script lang="ts">
import { cn } from '$lib/utils.js';
import type { WithElementRef } from 'bits-ui';
import type { HTMLAttributes } from 'svelte/elements';

let {
  ref = $bindable(null),
  class: className,
  level = 5,
  children,
  ...restProps
}: WithElementRef<HTMLAttributes<HTMLDivElement>> & {
  level?: 1 | 2 | 3 | 4 | 5 | 6;
} = $props();
</script>

<div
	role="heading"
	aria-level={level}
	bind:this={ref}
	class={cn("mb-1 font-medium leading-none tracking-tight", className)}
	{...restProps}
>
	{@render children?.()}
</div>
