import { useState } from 'react'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Toaster } from '@/components/ui/sonner'
import { OverviewSection } from '@/components/sections/OverviewSection'
import { APISection } from '@/components/sections/APISection'
import { ComponentsSection } from '@/components/sections/ComponentsSection'
import { ConfigSection } from '@/components/sections/ConfigSection'
import { UsageSection } from '@/components/sections/UsageSection'
import { TestingSection } from '@/components/sections/TestingSection'
import { Code, GitBranch, Package, Gear, Play, CheckCircle } from '@phosphor-icons/react'

function App() {
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <div className="min-h-screen bg-background">
      <div className="bg-gradient-to-br from-primary/10 via-background to-accent/5 border-b border-border">
        <div className="container mx-auto px-6 py-12 lg:px-12">
          <div className="flex flex-col gap-4">
            <div className="flex items-start gap-4">
              <div className="p-3 rounded-2xl bg-primary/20 backdrop-blur-sm">
                <GitBranch className="text-primary" size={32} weight="duotone" />
              </div>
              <div className="flex-1">
                <h1 className="text-4xl font-bold tracking-tight mb-2">
                  RecLLMGateway MVP
                </h1>
                <p className="text-lg text-muted-foreground max-w-3xl">
                  OpenAI-compatible LLM proxy with telemetry, usage tracking, and multi-provider routing
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-6 py-8 lg:px-12">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-2 lg:grid-cols-6 mb-8 h-auto p-1">
            <TabsTrigger value="overview" className="gap-2 py-3">
              <GitBranch className="hidden sm:block" size={18} />
              <span className="text-sm font-medium">Overview</span>
            </TabsTrigger>
            <TabsTrigger value="api" className="gap-2 py-3">
              <Code className="hidden sm:block" size={18} />
              <span className="text-sm font-medium">API</span>
            </TabsTrigger>
            <TabsTrigger value="components" className="gap-2 py-3">
              <Package className="hidden sm:block" size={18} />
              <span className="text-sm font-medium">Components</span>
            </TabsTrigger>
            <TabsTrigger value="config" className="gap-2 py-3">
              <Gear className="hidden sm:block" size={18} />
              <span className="text-sm font-medium">Config</span>
            </TabsTrigger>
            <TabsTrigger value="usage" className="gap-2 py-3">
              <Play className="hidden sm:block" size={18} />
              <span className="text-sm font-medium">Usage</span>
            </TabsTrigger>
            <TabsTrigger value="testing" className="gap-2 py-3">
              <CheckCircle className="hidden sm:block" size={18} />
              <span className="text-sm font-medium">Testing</span>
            </TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="mt-0">
            <OverviewSection />
          </TabsContent>

          <TabsContent value="api" className="mt-0">
            <APISection />
          </TabsContent>

          <TabsContent value="components" className="mt-0">
            <ComponentsSection />
          </TabsContent>

          <TabsContent value="config" className="mt-0">
            <ConfigSection />
          </TabsContent>

          <TabsContent value="usage" className="mt-0">
            <UsageSection />
          </TabsContent>

          <TabsContent value="testing" className="mt-0">
            <TestingSection />
          </TabsContent>
        </Tabs>
      </div>

      <footer className="border-t border-border mt-16">
        <div className="container mx-auto px-6 py-8 lg:px-12">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <p className="text-sm text-muted-foreground">
              RecLLMGateway MVP Specification
            </p>
            <p className="text-sm text-muted-foreground">
              Built for Elixir/Phoenix • OpenAI Compatible
            </p>
          </div>
        </div>
      </footer>

      <Toaster />
    </div>
  )
}

export default App
