Class {
	#name : #HopTraceTest,
	#superclass : #TestCase,
	#category : #HopTraceVisualization
}

{ #category : #tests }
HopTraceTest >> testModel [

	| m |
	m := HTVModel new.
	m parseJSONAsText: HopTraceExample new traceExample.
	self assert: m numberOfCalls equals: 97.
]

{ #category : #tests }
HopTraceTest >> testParseTrace [
 
	| v ds |
	v := (NeoJSONReader on: HopTraceExample new traceExample readStream) next.
	ds := (v at: 'calls') first at: 'calls'.
	self assert: ds size equals: 97.
	
]