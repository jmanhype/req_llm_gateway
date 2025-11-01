import React from 'react'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Package } from '@phosphor-icons/react'
import { Component } from '@/lib/spec-data'

interface ComponentCardProps {
  component: Component
}

export function ComponentCard({ component }: ComponentCardProps) {
  return (
    <Card className="p-5 hover:shadow-lg transition-shadow">
      <div className="flex flex-col gap-3">
        <div className="flex items-start gap-3">
          <div className="p-2 rounded-lg bg-primary/10">
            <Package className="text-primary" size={24} weight="duotone" />
          </div>
          <div className="flex-1">
            <h3 className="font-semibold text-lg">{component.name}</h3>
            <code className="text-xs text-muted-foreground font-mono">{component.file}</code>
          </div>
        </div>

        <p className="text-sm text-foreground">{component.description}</p>

        <div className="flex flex-col gap-2">
          <Badge variant="outline" className="self-start">Responsibility</Badge>
          <p className="text-sm text-muted-foreground leading-relaxed">
            {component.responsibility}
          </p>
        </div>
      </div>
    </Card>
  )
}
