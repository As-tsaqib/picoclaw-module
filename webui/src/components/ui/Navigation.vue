<template>
  <nav
    class="fixed bottom-4 left-4 right-4 z-40 max-w-md mx-auto rounded-3xl bg-surface-container-high/85 backdrop-blur-xl border border-white/10 shadow-[0_10px_38px_rgba(0,0,0,0.5)] p-1.5 transition-all duration-300 mb-[var(--window-inset-bottom,0px)]"
  >
    <div class="grid grid-cols-4 items-center gap-1">
      <router-link
        v-for="item in navItems"
        :key="item.path"
        :to="item.path"
        class="group relative flex flex-col items-center justify-center py-2 px-1 rounded-2xl no-underline transition-all duration-300"
        :class="isActive(item.path) ? 'text-on-primary-container' : 'text-on-surface-variant hover:text-on-surface'"
      >
        <!-- Active Background Pill -->
        <div
          v-if="isActive(item.path)"
          class="absolute inset-0 bg-primary/20 border border-primary/40 rounded-2xl transition-all duration-300 shadow-[0_0_15px_rgba(99,102,241,0.25)]"
        ></div>

        <!-- Icon Container -->
        <div
          class="relative z-10 p-1.5 rounded-xl transition-transform duration-300 group-active:scale-90"
          :class="isActive(item.path) ? 'scale-105 text-primary' : ''"
        >
          <component :is="item.icon" class="w-5 h-5 transition-colors" />
        </div>

        <!-- Label -->
        <span
          class="relative z-10 text-[0.65rem] font-bold tracking-tight mt-0.5 transition-colors"
          :class="isActive(item.path) ? 'text-primary font-extrabold' : ''"
        >
          {{ item.label }}
        </span>
      </router-link>
    </div>
  </nav>
</template>

<script setup>
import { useRoute } from 'vue-router';
import HomeIcon from '@/components/icons/HomeIcon.vue';
import AgentIcon from '@/components/icons/AgentIcon.vue';
import SettingsIcon from '@/components/icons/SettingsIcon.vue';
import LogsIcon from '@/components/icons/LogsIcon.vue';

const route = useRoute();

const navItems = [
  { path: '/', label: 'Dashboard', icon: HomeIcon },
  { path: '/agent', label: 'Console', icon: AgentIcon },
  { path: '/settings', label: 'Fitur', icon: SettingsIcon },
  { path: '/logs', label: 'Log', icon: LogsIcon },
];

function isActive(path) {
  if (path === '/') return route.path === '/';
  return route.path.startsWith(path);
}
</script>
