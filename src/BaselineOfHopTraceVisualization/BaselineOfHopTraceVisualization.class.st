Class {
	#name : #BaselineOfHopTraceVisualization,
	#superclass : #BaselineOf,
	#category : #BaselineOfHopTraceVisualization
}

{ #category : #baselines }
BaselineOfHopTraceVisualization >> baseline: spec [
	<baseline>

	spec for: #'common' do: [
		spec baseline: 'NeoJSON' with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
		
		spec baseline: 'Roassal3' with: [ 
				spec repository: 'github://ObjectProfile/Roassal3/src' ].
		
		spec 
			package: #'HopTraceVisualization' with: [
				spec requires: #('Roassal3' 'NeoJSON'). ].
		
		spec 
			group: 'Core' with: #('HopTraceVisualization' );
			group: 'default' with: #('HopTraceVisualization')
			].

]
