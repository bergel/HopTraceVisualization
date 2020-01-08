Class {
	#name : #HTVFunctionDefinition,
	#superclass : #Object,
	#instVars : [
		'functionName',
		'outgoingCalls',
		'positionStart',
		'positionEnd',
		'type'
	],
	#category : #HopTraceVisualization
}

{ #category : #accessing }
HTVFunctionDefinition >> functionName [
	^ functionName
]

{ #category : #accessing }
HTVFunctionDefinition >> functionName: anObject [
	functionName := anObject
]

{ #category : #accessing }
HTVFunctionDefinition >> outgoingCalls [
	^ outgoingCalls
]

{ #category : #accessing }
HTVFunctionDefinition >> outgoingCalls: anObject [
	outgoingCalls := anObject
]

{ #category : #accessing }
HTVFunctionDefinition >> positionEnd [
	^ positionEnd
]

{ #category : #accessing }
HTVFunctionDefinition >> positionEnd: anObject [
	positionEnd := anObject
]

{ #category : #accessing }
HTVFunctionDefinition >> positionStart [
	^ positionStart
]

{ #category : #accessing }
HTVFunctionDefinition >> positionStart: anObject [
	positionStart := anObject
]

{ #category : #accessing }
HTVFunctionDefinition >> type [
	^ type
]

{ #category : #accessing }
HTVFunctionDefinition >> type: anObject [
	type := anObject
]
