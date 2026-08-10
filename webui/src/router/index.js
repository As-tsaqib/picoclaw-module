import { createRouter, createWebHashHistory } from 'vue-router';
import HomeView from '@/views/HomeView.vue';
import AgentView from '@/views/AgentView.vue';
import SettingsView from '@/views/SettingsView.vue';
import LogsView from '@/views/LogsView.vue';

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'home', component: HomeView },
    { path: '/agent', name: 'agent', component: AgentView },
    { path: '/settings', name: 'settings', component: SettingsView },
    { path: '/logs', name: 'logs', component: LogsView },
  ],
});

export default router;
