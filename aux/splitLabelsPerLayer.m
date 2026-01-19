function splitLabelsPerLayer(fname, labels, outDir, prefix, sense)
	% Load Mask
	info = imfinfo(fname);
	[div] = imread(fname, 1, 'Info', info);

	lb = labels;

	newLb1 = filterByLayer(lb, div, 'layers12', sense);

	for i=1:10,
		suffix = sprintf('_layer%d.tif', i       );
		layers = sprintf('layers%d%d'  , i+1, i+2);

		newLb2 = filterByLayer(lb, div, layers, sense);

		if ~newLb2,
			lb = lb - newLb1;
			[newLb1, lb] = assignToFirstLayer(newLb1, lb);

			if any(newLb1(:)),
				writeMHDFile(newLb1, outDir, strcat(prefix, suffix));
				save(sprintf('%s/%s%s.mat', outDir, prefix, suffix), 'newLb1', '-v7.3');
			end

			break;
		end

		newLb2 = newLb2 - newLb1;

		[newLb1, newLb2] = assignToFirstLayer(newLb1, newLb2);

		if any(newLb1(:)),
			writeMHDFile(newLb1, outDir, strcat(prefix, suffix));
			save(sprintf('%s/%s%s.mat', outDir, prefix, suffix), 'newLb1', '-v7.3');
		end

		lb = lb - newLb1;

		newLb1 = newLb2;
	end

	suffix = sprintf('_layer%d.tif', i+1);

	if any(lb(:)),
		writeMHDFile(lb, outDir, strcat(prefix, suffix));
		save(sprintf('%s/%s%s.mat', outDir, prefix, suffix), 'lb', '-v7.3');
	end
end

function [newLb1, newLb2] = assignToFirstLayer(lb1, lb2)
	newLb1 = lb1;
	newLb2 = lb2;

	uni1 = unique(lb1);
	uni2 = unique(lb2);
	int  = intersect(uni1, uni2);

	for i=1:length(int),
		if int(i)~=0,
			newLb1(newLb2==int(i))=int(i);
			newLb2(newLb2==int(i))=0;
		end
	end
end

function [newLb] = filterByLayer(lb, div, layers, sense)
	if     strcmp(layers, 'layers12'  ),
		div=and(and((div(:,:,1)==255), (div(:,:,2)==  0)), (div(:,:,3)==  0));
	elseif strcmp(layers, 'layers23'  ),
		div=and(and((div(:,:,1)==0  ), (div(:,:,2)==255)), (div(:,:,3)==  0));
	elseif strcmp(layers, 'layers34'  ),
		div=and(and((div(:,:,1)==0  ), (div(:,:,2)==  0)), (div(:,:,3)==255));
	elseif strcmp(layers, 'layers45'  ),
		div=and(and((div(:,:,1)==255), (div(:,:,2)==255)), (div(:,:,3)==0  ));
	elseif strcmp(layers, 'layers56'  ),
		div=and(and((div(:,:,1)==255), (div(:,:,2)==  0)), (div(:,:,3)==255));
	elseif strcmp(layers, 'layers67'  ),
		div=and(and((div(:,:,1)==125), (div(:,:,2)==125)), (div(:,:,3)==125));
	elseif strcmp(layers, 'layers78'  ),
		div=and(and((div(:,:,1)==125), (div(:,:,2)==  0)), (div(:,:,3)==  0));
	elseif strcmp(layers, 'layers89'  ),
		div=and(and((div(:,:,1)==  0), (div(:,:,2)==125)), (div(:,:,3)==  0));
	elseif strcmp(layers, 'layers910' ),
		div=and(and((div(:,:,1)==  0), (div(:,:,2)==  0)), (div(:,:,3)==125));
	elseif strcmp(layers, 'layers1011'),
		div=and(and((div(:,:,1)==125), (div(:,:,2)==125)), (div(:,:,3)==  0));
	elseif strcmp(layers, 'layers1112'),
		div=and(and((div(:,:,1)==125), (div(:,:,2)==  0)), (div(:,:,3)==125));
	else
		error('Wrong layer division selected. Aborting...')
	end
		
	div=bwmorph(div,'skel',Inf);

	% Extract points and complete line
	[row, col] = find(div);

	if isempty(row),
		newLb = false;
	else,
		if     strcmpi(sense, 'horizontal'),
			[row, col] = completeLinesHorizontal(row, col);
		elseif strcmpi(sense, 'vertical'),
			[row, col] = completeLinesVertical(row, col);
		else
			error('Wrong sense for the splitting');
		end

		newLb = uint16(zeros(size(lb)));

		for i=1:length(row),
			if     strcmpi(sense, 'horizontal'),
				newLb(1:row(i), col(i):col(i), :)=lb(1:row(i), col(i):col(i), :);
			else
				newLb(row(i):row(i), 1:col(i), :)=lb(row(i):row(i), 1:col(i), :);
			end
		end
	end
end

function [newRow, newCol] = completeLinesHorizontal(row, col)
	pos=find(col==min(col));
	r=row(pos(1));
	c=col(pos(1))-1;

	newRow=row;
	newCol=col;

	while c>=1,
		newRow(end+1)=r;
		newCol(end+1)=c;
		c=c-1;
	end
end

function [newRow, newCol] = completeLinesVertical(row, col)
	pos=find(row==min(row));
	r=row(pos(1))-1;
	c=col(pos(1));

	newRow=row;
	newCol=col;

	while r>=1,
		newRow(end+1)=r;
		newCol(end+1)=c;
		r=r-1;
	end
end
