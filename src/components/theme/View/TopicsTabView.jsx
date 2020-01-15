/**
 * Document view component.
 * @module components/theme/View/DefaultView
 */

import React from 'react';
import { Helmet } from '@plone/volto/helpers';
import { compose } from 'redux';
import { defineMessages, injectIntl } from 'react-intl';

import { map } from 'lodash';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';

import { blocks } from '~/config';
import {
  getBlocksFieldname,
  getBlocksLayoutFieldname,
  hasBlocksData,
} from '@plone/volto/helpers';
import { flattenToAppURL } from '@plone/volto/helpers';
import { samePath } from 'volto-mosaic/helpers';

const messages = defineMessages({
  unknownBlock: {
    id: 'Unknown Block',
    defaultMessage: 'Unknown Block {block}',
  },
});

const computeFolderTabs = siblings => {
  const tabsItems = siblings.items.map(i => {
    return {
      url: flattenToAppURL(i.url),
      title: i.name,
    };
  });
  return tabsItems;
};
const TopicsTabView = props => {
  const content = props.content;
  const intl = props.intl;
  const blocksFieldname = getBlocksFieldname(content);
  const blocksLayoutFieldname = getBlocksLayoutFieldname(content);
  const tabs = computeFolderTabs(content['@components'].siblings);
  const currentUrl = props.content?.['@id'];
  const shouldRenderRoutes =
    typeof currentUrl !== 'undefined' && samePath(currentUrl, props.pathname)
      ? true
      : false;

  return (
    hasBlocksData(content) && (
      <div id="page-document" className="ui wrapper">
        {tabs && tabs.length ? (
          <nav className="tabs">
            {tabs.map(tab => (
              <Link
                className={`${!shouldRenderRoutes ? 'blurred' : ''}`}
                key={`localtab-${tab.url}`}
                className={`tabs__item${(tab.url === props.location.pathname &&
                  ' tabs__item_active') ||
                  ''}${!shouldRenderRoutes ? ' blurred' : ''}`}
                to={tab.url}
                title={tab.title}
              >
                {tab.title}
              </Link>
            ))}
          </nav>
        ) : (
          ''
        )}
        <Helmet title={content.title} />
        {map(content[blocksLayoutFieldname].items, block => {
          const Block =
            blocks.blocksConfig[
              (content[blocksFieldname]?.[block]?.['@type'])
            ]?.['view'] || null;
          return Block !== null ? (
            <div className={`${!shouldRenderRoutes ? 'blurred' : ''}`}>
              <Block
                key={`block-${block}`}
                blockID={block}
                properties={content}
                data={content[blocksFieldname][block]}
              />
            </div>
          ) : (
            <div key={`blocktype-${block}`}>
              {intl.formatMessage(messages.unknownBlock, {
                block: content[blocksFieldname]?.[block]?.['@type'],
              })}
            </div>
          );
        })}
      </div>
    )
  );
};

export default compose(
  injectIntl,
  connect((state, props) => ({
    pathname: props.location.pathname,
  })),
)(TopicsTabView);
