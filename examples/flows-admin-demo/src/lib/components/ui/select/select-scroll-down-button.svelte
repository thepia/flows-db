<script lang="ts">
import { cn } from '$lib/utils.js';
import type { Select as SelectPrimitive, WithoutChildrenOrChild } from 'bits-ui';
import { ChevronDown } from 'lucide-svelte';

let {
  ref = $bindable(null),
  class: className,
  ...restProps
}: WithoutChildrenOrChild<SelectPrimitive.ScrollDownButtonProps> = $props();
</script>

<SelectPrimitive.ScrollDownButton
	bind:ref
	class={cn("flex cursor-default items-center justify-center py-1", className)}
	{...restProps}
>
	<ChevronDown class="size-4" />
</SelectPrimitive.ScrollDownButton>
