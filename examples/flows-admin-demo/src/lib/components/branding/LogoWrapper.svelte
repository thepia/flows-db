<script lang="ts">
	// Props
	export let variant: 'square' | 'horizontal' = 'square';
	export let className: string = '';
</script>

<!-- Simple Thepia logo using inline SVG for now -->
<div class="w-full h-full flex items-center justify-center bg-blue-600 rounded {variant === 'square' ? '' : 'px-2'} {className}">
	<svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
		<path d="M3 3h6v6H3V3zm8 0h6v6h-6V3zM3 11h6v6H3v-6zm8 0h6v6h-6v-6z"/>
	</svg>
</div>