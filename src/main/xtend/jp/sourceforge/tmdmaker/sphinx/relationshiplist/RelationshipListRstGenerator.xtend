/*
 * Copyright 2016 TMD-Maker Project <http://tmdmaker.osdn.jp/>
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
package jp.sourceforge.tmdmaker.sphinx.relationshiplist

import java.io.File
import java.util.List
import java.util.LinkedHashMap
import java.util.ArrayList
import jp.sourceforge.tmdmaker.model.AbstractEntityModel
import jp.sourceforge.tmdmaker.model.RecursiveTable
import jp.sourceforge.tmdmaker.model.RecursiveRelationship
import jp.sourceforge.tmdmaker.sphinx.utilities.SphinxUtils
import java.util.HashMap
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Relationship の検証表を生成する。
 * 
 * @author tohosaku
 */
class RelationshipListRstGenerator {
	
	def static execute(File outputdir, List<AbstractEntityModel> models) {
		
        outputdir.mkdirs()
        
		val relationshipMappingMap = createData(models)
		
		var table = new HashMap<AbstractEntityModel,ArrayList<String>>
		for (mapping: relationshipMappingMap.entrySet())
		{
			var row = new ArrayList<String>
			var isWrite = true
			for (rm: mapping.value)
			{
				row.add(cellValue(isWrite,rm.relationship))
				if (rm.target == mapping.key)
				{
					isWrite = false
				}
			}
			table.put(mapping.key,row)
		}
	
		SphinxUtils.writeFile(
			new File(outputdir, "relationship_list.rst"),
			relationshipList(table).toString)
	}
	
	def static private cellValue(boolean isWrite, boolean relationship)
	{
		if (isWrite == true)
		{
			if(relationship == true)
			{
				"○"
			}
			else{
				"×"
			}
		}
		else{
			"\\-"
		}		
	}
	
	def static private createData(List<AbstractEntityModel> models) {
		var relationshipMappingMap = new LinkedHashMap<AbstractEntityModel, List<RelationshipMapping>>()
		for (source : models) {
			var relationshipMappingList = new ArrayList<RelationshipMapping>()
			for (target : models) {
				relationshipMappingList.add(new RelationshipMapping(source,target))
			}
			relationshipMappingMap.put(source, relationshipMappingList)
		}
		relationshipMappingMap
	}
	
	def static private relationshipList(Map<AbstractEntityModel,ArrayList<String>> table) '''
		リレーションシップの検証表
		===========================
		
		.. list-table::
		   :header-rows: 1
		
		   * - 
		     «FOR entity : table.keySet()»
		     - «entity.name»
		     «ENDFOR»
		   «FOR mapping : table.entrySet()»
		   * - «mapping.key.name»
		     «FOR rm : mapping.value»
		     - «rm»
		     «ENDFOR»
		«ENDFOR»
	'''
}

class RelationshipMapping {
	
	/** 比較元 */
	@Accessors(PUBLIC_GETTER) AbstractEntityModel source
	/** 比較先 */
	@Accessors(PUBLIC_GETTER) AbstractEntityModel target
	/** リレーションシップ有無 */
	private boolean relationship = false
	
	/**
	 * コンストラクタ
	 * 
	 * @param source
	 * @param target
	 */
	new(AbstractEntityModel source, AbstractEntityModel target) {
		this.source = source
		this.target = target

		if (   hasRecursiveRelationship()
			|| hasRelationshipAsSource()
			|| hasRelationshipAsTarget()
		) {
			relationship = true
		} else {
			relationship = false
		}

		if (isRecursiveTablePair()) {
			relationship = false
		}
	}
	/**
	 * 再帰表とそのリレーションシップ元との組合せか？
	 * 
	 * @return 比較元・先が再帰表とそのリレーションシップ元である場合にtrueを返す
	 */
	def private isRecursiveTablePair() {
		if (target instanceof RecursiveTable) {
			return (target as RecursiveTable).isSource(source)
		} else if (source instanceof RecursiveTable) {
			return (source as RecursiveTable).isSource(target)
		}
		return false;
	}

	/**
	 * 再帰表を作成しているか？
	 * 
	 * @return 再帰表を作成している場合にtrueを返す
	 */
	def hasRecursiveRelationship() {
		source == target &&
		source.modelSourceConnections.exists[c| c instanceof RecursiveRelationship]
	}

	/**
	 * 比較元が接続元、比較先が接続先としてリレーションシップを作成しているか？
	 * 
	 * @return リレーションシップを作成している場合にtrueを返す
	 */
	def private boolean hasRelationshipAsSource() {
		source.modelSourceConnections.exists[c|c.target.equals(target)]
	}

	/**
	 * 比較元が接続先、比較先が接続元としてリレーションシップを作成しているか？
	 * 
	 * @return リレーションシップを作成している場合にtrueを返す
	 */
	def private hasRelationshipAsTarget() {
		source.modelTargetConnections.exists[c|c.source.equals(target)]
	}

	/**
	 * @return the relationship
	 */
	def isRelationship() {
		relationship
	}
}