<script lang="ts">
export const message: string = 'Loading demo data...';
export const size: 'sm' | 'md' | 'lg' = 'md';

// Size mappings
$: containerSize = {
  sm: 'w-32 h-32',
  md: 'w-48 h-48',
  lg: 'w-64 h-64',
}[size];

$: textSize = {
  sm: 'text-sm',
  md: 'text-base',
  lg: 'text-lg',
}[size];
</script>

<div class="flex flex-col items-center justify-center space-y-4">
	<!-- Animated SVG -->
	<div class="{containerSize}">
		<svg viewBox="0 0 120 80" class="w-full h-full">
			<!-- Background office building -->
			<rect x="20" y="35" width="80" height="40" fill="#f3f4f6" stroke="#d1d5db" stroke-width="1" rx="2" />
			<rect x="25" y="40" width="8" height="8" fill="#e5e7eb" />
			<rect x="35" y="40" width="8" height="8" fill="#e5e7eb" />
			<rect x="45" y="40" width="8" height="8" fill="#e5e7eb" />
			<rect x="55" y="40" width="8" height="8" fill="#e5e7eb" />
			<rect x="65" y="40" width="8" height="8" fill="#e5e7eb" />
			<rect x="75" y="40" width="8" height="8" fill="#e5e7eb" />
			<rect x="85" y="40" width="8" height="8" fill="#e5e7eb" />
			
			<rect x="25" y="52" width="8" height="8" fill="#e5e7eb" />
			<rect x="35" y="52" width="8" height="8" fill="#e5e7eb" />
			<rect x="45" y="52" width="8" height="8" fill="#e5e7eb" />
			<rect x="55" y="52" width="8" height="8" fill="#e5e7eb" />
			<rect x="65" y="52" width="8" height="8" fill="#e5e7eb" />
			<rect x="75" y="52" width="8" height="8" fill="#e5e7eb" />
			<rect x="85" y="52" width="8" height="8" fill="#e5e7eb" />
			
			<!-- Door -->
			<rect x="55" y="60" width="10" height="15" fill="#9ca3af" rx="1" />
			
			<!-- People figures walking into the building -->
			<!-- Person 1 - Coming from left -->
			<g class="person-1">
				<!-- Head -->
				<circle cx="10" cy="55" r="3" fill="#3b82f6" />
				<!-- Body -->
				<rect x="8" y="58" width="4" height="8" fill="#3b82f6" rx="2" />
				<!-- Legs -->
				<rect x="8.5" y="66" width="1.5" height="6" fill="#3b82f6" />
				<rect x="10" y="66" width="1.5" height="6" fill="#3b82f6" />
				<!-- Arms -->
				<rect x="6.5" y="60" width="1.5" height="4" fill="#3b82f6" />
				<rect x="11.5" y="60" width="1.5" height="4" fill="#3b82f6" />
				
				<animateTransform
					attributeName="transform"
					type="translate"
					values="0,0; 50,0; 50,0"
					dur="3s"
					repeatCount="indefinite"
				/>
			</g>
			
			<!-- Person 2 - Coming from right -->
			<g class="person-2">
				<!-- Head -->
				<circle cx="110" cy="55" r="3" fill="#10b981" />
				<!-- Body -->
				<rect x="108" y="58" width="4" height="8" fill="#10b981" rx="2" />
				<!-- Legs -->
				<rect x="108.5" y="66" width="1.5" height="6" fill="#10b981" />
				<rect x="110" y="66" width="1.5" height="6" fill="#10b981" />
				<!-- Arms -->
				<rect x="106.5" y="60" width="1.5" height="4" fill="#10b981" />
				<rect x="111.5" y="60" width="1.5" height="4" fill="#10b981" />
				
				<animateTransform
					attributeName="transform"
					type="translate"
					values="0,0; -50,0; -50,0"
					dur="3s"
					begin="1s"
					repeatCount="indefinite"
				/>
			</g>
			
			<!-- Person 3 - Coming from top -->
			<g class="person-3">
				<!-- Head -->
				<circle cx="60" cy="20" r="3" fill="#f59e0b" />
				<!-- Body -->
				<rect x="58" y="23" width="4" height="8" fill="#f59e0b" rx="2" />
				<!-- Legs -->
				<rect x="58.5" y="31" width="1.5" height="6" fill="#f59e0b" />
				<rect x="60" y="31" width="1.5" height="6" fill="#f59e0b" />
				<!-- Arms -->
				<rect x="56.5" y="25" width="1.5" height="4" fill="#f59e0b" />
				<rect x="61.5" y="25" width="1.5" height="4" fill="#f59e0b" />
				
				<animateTransform
					attributeName="transform"
					type="translate"
					values="0,0; 0,20; 0,20"
					dur="3s"
					begin="2s"
					repeatCount="indefinite"
				/>
			</g>
			
			<!-- Floating documents -->
			<g class="documents">
				<!-- Document 1 -->
				<rect x="25" y="20" width="6" height="8" fill="#ffffff" stroke="#d1d5db" rx="1">
					<animate attributeName="y" values="20;15;20" dur="2s" repeatCount="indefinite" />
					<animate attributeName="opacity" values="0;1;0" dur="2s" repeatCount="indefinite" />
				</rect>
				
				<!-- Document 2 -->
				<rect x="85" y="25" width="6" height="8" fill="#ffffff" stroke="#d1d5db" rx="1">
					<animate attributeName="y" values="25;20;25" dur="2.5s" begin="0.5s" repeatCount="indefinite" />
					<animate attributeName="opacity" values="0;1;0" dur="2.5s" begin="0.5s" repeatCount="indefinite" />
				</rect>
				
				<!-- Document 3 -->
				<rect x="40" y="15" width="6" height="8" fill="#ffffff" stroke="#d1d5db" rx="1">
					<animate attributeName="y" values="15;10;15" dur="3s" begin="1s" repeatCount="indefinite" />
					<animate attributeName="opacity" values="0;1;0" dur="3s" begin="1s" repeatCount="indefinite" />
				</rect>
			</g>
			
			<!-- Checkmarks appearing -->
			<g class="checkmarks">
				<!-- Checkmark 1 -->
				<g fill="#10b981" stroke="#10b981" stroke-width="2">
					<path d="M 75 30 L 77 32 L 80 28" fill="none" stroke-linecap="round">
						<animate attributeName="opacity" values="0;1;0" dur="1.5s" begin="1s" repeatCount="indefinite" />
					</path>
				</g>
				
				<!-- Checkmark 2 -->
				<g fill="#10b981" stroke="#10b981" stroke-width="2">
					<path d="M 90 35 L 92 37 L 95 33" fill="none" stroke-linecap="round">
						<animate attributeName="opacity" values="0;1;0" dur="1.5s" begin="2s" repeatCount="indefinite" />
					</path>
				</g>
				
				<!-- Checkmark 3 -->
				<g fill="#10b981" stroke="#10b981" stroke-width="2">
					<path d="M 30 28 L 32 30 L 35 26" fill="none" stroke-linecap="round">
						<animate attributeName="opacity" values="0;1;0" dur="1.5s" begin="3s" repeatCount="indefinite" />
					</path>
				</g>
			</g>
			
			<!-- Flowing data lines -->
			<g stroke="#3b82f6" stroke-width="1" fill="none" opacity="0.6">
				<path d="M 0 70 Q 30 65 60 70 Q 90 75 120 70">
					<animate attributeName="stroke-dasharray" values="0 120; 120 0" dur="2s" repeatCount="indefinite" />
				</path>
				<path d="M 0 74 Q 20 72 60 74 Q 100 76 120 74">
					<animate attributeName="stroke-dasharray" values="0 120; 120 0" dur="2.5s" begin="0.5s" repeatCount="indefinite" />
				</path>
			</g>
			
			<!-- Sparkles -->
			<g class="sparkles">
				<g fill="#fbbf24">
					<circle cx="15" cy="45" r="1">
						<animate attributeName="opacity" values="0;1;0" dur="1s" repeatCount="indefinite" />
					</circle>
					<circle cx="105" cy="50" r="1">
						<animate attributeName="opacity" values="0;1;0" dur="1.2s" begin="0.3s" repeatCount="indefinite" />
					</circle>
					<circle cx="70" cy="25" r="1">
						<animate attributeName="opacity" values="0;1;0" dur="0.8s" begin="0.6s" repeatCount="indefinite" />
					</circle>
					<circle cx="35" cy="65" r="1">
						<animate attributeName="opacity" values="0;1;0" dur="1.5s" begin="0.9s" repeatCount="indefinite" />
					</circle>
				</g>
			</g>
			
			<!-- Company logo/icon in building -->
			<circle cx="60" cy="45" r="4" fill="#6366f1" opacity="0.8">
				<animate attributeName="r" values="4;5;4" dur="2s" repeatCount="indefinite" />
			</circle>
			<text x="60" y="48" font-family="Arial" font-size="3" fill="white" text-anchor="middle">F</text>
		</svg>
	</div>
	
	<!-- Loading message -->
	<div class="text-center">
		<p class="{textSize} text-gray-600 font-medium">{message}</p>
		<div class="flex items-center justify-center space-x-1 mt-2">
			<div class="w-2 h-2 bg-blue-500 rounded-full animate-bounce"></div>
			<div class="w-2 h-2 bg-blue-500 rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
			<div class="w-2 h-2 bg-blue-500 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
		</div>
	</div>
</div>

<style>
	/* Additional smooth animations */
	.person-1, .person-2, .person-3 {
		transform-origin: center;
	}
	
	/* Subtle floating effect for the whole container */
	svg {
		animation: float 6s ease-in-out infinite;
	}
	
	@keyframes float {
		0%, 100% { transform: translateY(0px); }
		50% { transform: translateY(-3px); }
	}
</style>