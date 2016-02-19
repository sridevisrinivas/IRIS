package com.temenos.interaction.translate.loader;

/*
 * #%L
 * %%
 * Copyright (C) 2012 - 2016 Temenos Holdings N.V.
 * %%
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * #L%
 */


import java.io.File;
import java.util.Collection;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.temenos.interaction.core.hypermedia.FileMappingResourceStateProvider;
import com.temenos.interaction.core.loader.Action;
import com.temenos.interaction.core.loader.FileEvent;

/**
 * Handle a file change event by loading and mapping created/updated RIM
 * files.
 *  
 * @author dgroves
 * @author hmanchala
 */
public class ResourceSetGeneratorAction implements Action<FileEvent<File>> {

    private static final Logger logger = LoggerFactory.getLogger(ResourceSetGeneratorAction.class);
    
    private FileMappingResourceStateProvider resourceStateProvider;
    private boolean available;
    
    @Override
    public synchronized void execute(FileEvent<File> dirEvent) {
    	this.available = false;
    	logger.info("File change or new files detected in {}", 
        		dirEvent.getResource().getAbsolutePath());
        Collection<File> rims = FileUtils.listFiles(
    		dirEvent.getResource(), new String[]{"rim"}, true
		);
        if(rims.isEmpty()){
        	logger.info("Couldn't find any RIM file changes; skipping registration.");
        	return;
        }
        this.resourceStateProvider.loadAndMapFileObjects(rims);
        this.available = true;
        notifyAll();
    }
	    
    public void setResourceStateProvider(FileMappingResourceStateProvider resourceStateProvider){
        this.resourceStateProvider = resourceStateProvider;
    }
    
    public boolean isAvailable(){
    	return available;
    }
}