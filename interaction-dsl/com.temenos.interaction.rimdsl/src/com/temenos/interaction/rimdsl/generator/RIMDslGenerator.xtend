/*
 * generated by Xtext
 */
package com.temenos.interaction.rimdsl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import com.temenos.interaction.rimdsl.rim.ResourceCommand
import com.temenos.interaction.rimdsl.rim.State
import com.temenos.interaction.rimdsl.rim.Transition
import com.temenos.interaction.rimdsl.rim.TransitionForEach
import com.temenos.interaction.rimdsl.rim.TransitionAuto
import com.temenos.interaction.rimdsl.rim.ResourceInteractionModel
import org.eclipse.emf.common.util.EList
import com.temenos.interaction.rimdsl.rim.UriLink
import com.temenos.interaction.rimdsl.rim.UriLinkageEntityKeyReplace
import com.temenos.interaction.rimdsl.rim.OKFunction;
import com.temenos.interaction.rimdsl.rim.NotFoundFunction
import com.temenos.interaction.rimdsl.rim.Function

class RIMDslGenerator implements IGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		fsa.generateFile(resource.className + "Model" + "/" + resource.className+"Behaviour.java", toJavaCode(resource.contents.head as ResourceInteractionModel))
	}
	
	def className(Resource res) {
		var name = res.URI.lastSegment
		return name.substring(0, name.indexOf('.'))
	}
	
	def toJavaCode(ResourceInteractionModel rim) '''
		package «rim.eResource.className»Model;

		import java.util.ArrayList;
		import java.util.HashMap;
		import java.util.List;
		import java.util.Map;
		import java.util.Properties;

		import com.temenos.interaction.core.hypermedia.UriSpecification;
		import com.temenos.interaction.core.hypermedia.Action;
		import com.temenos.interaction.core.hypermedia.CollectionResourceState;
		import com.temenos.interaction.core.hypermedia.ResourceState;
		import com.temenos.interaction.core.hypermedia.ResourceStateMachine;
		import com.temenos.interaction.core.hypermedia.validation.HypermediaValidator;
		import com.temenos.interaction.core.hypermedia.expression.ResourceGETExpression;
		
		public class «rim.eResource.className»Behaviour {
		
		    public static void main(String[] args) {
		        ResourceStateMachine hypermediaEngine = new ResourceStateMachine(new «rim.eResource.className»Behaviour().getRIM());
		        HypermediaValidator validator = HypermediaValidator.createValidator(hypermediaEngine);
		        System.out.println(validator.graph());
		    }
		
			public ResourceState getRIM() {
				Map<String, String> uriLinkageEntityProperties = new HashMap<String, String>();
				Map<String, String> uriLinkageProperties = new HashMap<String, String>();
				Properties actionViewProperties;
				ResourceState initial = null;
				// create states
				«FOR c : rim.states»
					«c.produceResourceStates»
					«IF c.isInitial»
					// identify the initial state
					initial = s«c.name»;
					«ENDIF»
				«ENDFOR»

				// create regular transitions
				«FOR c : rim.states»
					«FOR t : c.transitions»
						«produceTransitions(c, t)»
					«ENDFOR»
				«ENDFOR»

		        // create foreach transitions
                «FOR c : rim.states»
                    «FOR t : c.transitionsForEach»
                        «produceTransitionsForEach(c, t)»
                    «ENDFOR»
                «ENDFOR»

		        // create AUTO transitions
                «FOR c : rim.states»
                    «FOR t : c.transitionsAuto»
                        «produceTransitionsAuto(c, t)»
                    «ENDFOR»
                «ENDFOR»

			    return initial;
			}

		}
	'''
	
	def produceResourceStates(State state) '''
            «produceActionSet(state, state.view, state.actions)»
            «produceRelations(state)»
            «IF state.entity.isCollection»
            CollectionResourceState s«state.name» = new CollectionResourceState("«state.entity.name»", "«state.name»", «state.name»Actions, "«if (state.path != null) { state.path.name } else { "/" + state.name }»", «state.name»Relations, null);
            «ELSEIF state.entity.isItem»
            ResourceState s«state.name» = new ResourceState("«state.entity.name»", "«state.name»", «state.name»Actions, "«if (state.path != null) { state.path.name } else { "/" + state.name }»", «state.name»Relations«if (state.path != null) { ", new UriSpecification(\"" + state.name + "\", \"" + state.path.name + "\")" }»);
            «ENDIF»
	'''

    def produceRelations(State state) '''
        «IF state.relations != null && state.relations.size > 0»
        String «state.name»RelationsStr = "";
        «FOR relation : state.relations»
        «state.name»RelationsStr += "«relation.name» ";
        «ENDFOR»
        String[] «state.name»Relations = «state.name»RelationsStr.trim().split(" ");
        «ELSE»
        String[] «state.name»Relations = null;
        «ENDIF»
    '''

    def produceActionSet(State state, ResourceCommand view, EList<ResourceCommand> actions) '''
        List<Action> «state.name»Actions = new ArrayList<Action>();
        «IF view != null && (view.command.properties.size > 0 || view.parameters.size > 0)»
            actionViewProperties = new Properties();
            «FOR commandProperty :view.command.properties»
            actionViewProperties.put("«commandProperty.name»", "«commandProperty.value»");
            «ENDFOR»
            «FOR commandProperty :view.parameters»
            actionViewProperties.put("«commandProperty.name»", "«commandProperty.value»");
            «ENDFOR»
        «ENDIF»
        «IF view != null»
        «state.name»Actions.add(new Action("«view.command.name»", Action.TYPE.VIEW, «if (view != null && (view.command.properties.size > 0 || view.parameters.size > 0)) { "actionViewProperties" } else { "new Properties()" }»));
        «ENDIF»
        «IF actions != null»
            «FOR action : actions»
            actionViewProperties = new Properties();
            «IF action != null && (action.command.properties.size > 0 || action.parameters.size > 0)»
                «FOR commandProperty :action.command.properties»
                actionViewProperties.put("«commandProperty.name»", "«commandProperty.value»");
                «ENDFOR»
                «FOR commandProperty :action.parameters»
                actionViewProperties.put("«commandProperty.name»", "«commandProperty.value»");
                «ENDFOR»
            «ENDIF»
            «state.name»Actions.add(new Action("«action.command.name»", Action.TYPE.ENTRY, actionViewProperties));
            «ENDFOR»
        «ENDIF»'''
    
	def produceTransitions(State fromState, Transition transition) '''
            «IF transition.eval != null»
            «produceUriLinkage(transition.uriLinks)»
            s«fromState.name».addTransition("«transition.event.httpMethod»", s«transition.state.name», uriLinkageEntityProperties, uriLinkageProperties, 0, «produceExpression(transition.eval.expressions.get(0))», «if (transition.title != null) { "\"" + transition.title.name + "\"" } else { "\"" + transition.state.name + "\"" }»);
            «ELSE»
            «produceUriLinkage(transition.uriLinks)»
            s«fromState.name».addTransition("«transition.event.httpMethod»", s«transition.state.name», uriLinkageEntityProperties, uriLinkageProperties, «if (transition.title != null) { "\"" + transition.title.name + "\"" } else { "\"" + transition.state.name + "\"" }»);
            «ENDIF»
	'''

    def produceExpression(Function expression) '''
        «IF expression instanceof OKFunction»
            new ResourceGETExpression("«(expression as OKFunction).state.name»", ResourceGETExpression.Function.OK)«
        ELSE»
            new ResourceGETExpression("«(expression as NotFoundFunction).state.name»", ResourceGETExpression.Function.NOT_FOUND)«
        ENDIF»'''

    def produceTransitionsForEach(State fromState, TransitionForEach transition) '''
            «produceUriLinkage(transition.uriLinks)»
            s«fromState.name».addTransitionForEachItem("«transition.event.httpMethod»", s«transition.state.name», uriLinkageEntityProperties, uriLinkageProperties, «if (transition.title != null) { "\"" + transition.title.name + "\"" } else { "\"" + transition.state.name + "\"" }»);
    '''
		
    def produceTransitionsAuto(State fromState, TransitionAuto transition) '''
            s«fromState.name».addTransition(s«transition.state.name»);
    '''

    def produceUriLinkage(EList<UriLink> uriLinks) '''
        «IF uriLinks != null»
            «FOR prop : uriLinks»
            «IF prop.entityProperty instanceof UriLinkageEntityKeyReplace»
            uriLinkageEntityProperties.put("«prop.templateProperty»", "«prop.entityProperty.name»");
            «ELSE»
            uriLinkageProperties.put("«prop.templateProperty»", "«prop.entityProperty.name»");
            «ENDIF»
            «ENDFOR»«
        ENDIF»
    '''

}

